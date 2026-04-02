from dotenv import load_dotenv
from pathlib import Path

ROOT_DIR = Path(__file__).parent
load_dotenv(ROOT_DIR / '.env')

from fastapi import FastAPI, APIRouter, HTTPException, Request, Response, Depends
from starlette.middleware.cors import CORSMiddleware
from motor.motor_asyncio import AsyncIOMotorClient
import os
import logging
from pydantic import BaseModel, Field
from typing import List, Optional
import uuid
from datetime import datetime, timezone, timedelta
import bcrypt
import jwt
import json
import base64
import io
import qrcode
from bson import ObjectId
from collections import deque

# MongoDB connection
mongo_url = os.environ['MONGO_URL']
client = AsyncIOMotorClient(mongo_url)
db = client[os.environ['DB_NAME']]

app = FastAPI()
api_router = APIRouter(prefix="/api")

JWT_ALGORITHM = "HS256"

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

# ======================== HELPERS ========================

def get_jwt_secret():
    return os.environ["JWT_SECRET"]

def hash_password(password: str) -> str:
    salt = bcrypt.gensalt()
    return bcrypt.hashpw(password.encode("utf-8"), salt).decode("utf-8")

def verify_password(plain: str, hashed: str) -> bool:
    return bcrypt.checkpw(plain.encode("utf-8"), hashed.encode("utf-8"))

def create_access_token(user_id: str, email: str) -> str:
    payload = {"sub": user_id, "email": email, "exp": datetime.now(timezone.utc) + timedelta(minutes=60), "type": "access"}
    return jwt.encode(payload, get_jwt_secret(), algorithm=JWT_ALGORITHM)

def create_refresh_token(user_id: str) -> str:
    payload = {"sub": user_id, "exp": datetime.now(timezone.utc) + timedelta(days=7), "type": "refresh"}
    return jwt.encode(payload, get_jwt_secret(), algorithm=JWT_ALGORITHM)

async def get_current_user(request: Request) -> dict:
    token = request.cookies.get("access_token")
    if not token:
        auth_header = request.headers.get("Authorization", "")
        if auth_header.startswith("Bearer "):
            token = auth_header[7:]
    if not token:
        raise HTTPException(status_code=401, detail="Not authenticated")
    try:
        payload = jwt.decode(token, get_jwt_secret(), algorithms=[JWT_ALGORITHM])
        if payload.get("type") != "access":
            raise HTTPException(status_code=401, detail="Invalid token type")
        user = await db.users.find_one({"_id": ObjectId(payload["sub"])})
        if not user:
            raise HTTPException(status_code=401, detail="User not found")
        user["_id"] = str(user["_id"])
        user.pop("password_hash", None)
        return user
    except jwt.ExpiredSignatureError:
        raise HTTPException(status_code=401, detail="Token expired")
    except jwt.InvalidTokenError:
        raise HTTPException(status_code=401, detail="Invalid token")

def generate_qr_base64(data: str) -> str:
    qr = qrcode.QRCode(version=1, box_size=10, border=4)
    qr.add_data(data)
    qr.make(fit=True)
    img = qr.make_image(fill_color="white", back_color="#0A0A0B")
    buffer = io.BytesIO()
    img.save(buffer, format="PNG")
    return base64.b64encode(buffer.getvalue()).decode("utf-8")

# ======================== MODELS ========================

class AuthRegister(BaseModel):
    name: str
    email: str
    password: str

class AuthLogin(BaseModel):
    email: str
    password: str

class RouteRequest(BaseModel):
    source: str
    destination: str

class TicketBookRequest(BaseModel):
    source: str
    destination: str
    fare: float
    num_passengers: int = 1

class TopUpRequest(BaseModel):
    amount: float

class ChatRequest(BaseModel):
    message: str
    session_id: Optional[str] = None

class ForgotPasswordRequest(BaseModel):
    email: str

class ResetPasswordRequest(BaseModel):
    token: str
    new_password: str

# ======================== KOLKATA METRO DATA ========================

METRO_LINES = {
    "blue": {
        "name": "Blue Line (Line 1)",
        "color": "#0078D7",
        "stations": [
            "Dakshineswar", "Baranagar", "Noapara", "Dum Dum", "Belgachia",
            "Shyambazar", "Shobhabazar Sutanuti", "Girish Park", "Mahatma Gandhi Road",
            "Central", "Chandni Chowk", "Esplanade", "Park Street", "Maidan",
            "Rabindra Sadan", "Netaji Bhawan", "Jatin Das Park", "Kalighat",
            "Rabindra Sarobar", "Masterda Surya Sen", "Netaji", "Kavi Subhash"
        ]
    },
    "green": {
        "name": "Green Line (Line 2)",
        "color": "#00B259",
        "stations": [
            "Salt Lake Sector V", "Karunamoyee", "Central Park", "City Centre",
            "Bengal Chemical", "Phool Bagan", "Sealdah", "Esplanade",
            "Mahakaran", "Howrah", "Howrah Maidan"
        ]
    },
    "purple": {
        "name": "Purple Line (Line 3)",
        "color": "#800080",
        "stations": [
            "Joka", "Thakurpukur", "Sakher Bazar", "Behala Chowrasta",
            "Behala Bazar", "Taratala", "Majerhat", "Rabindra Sadan",
            "Esplanade"
        ]
    },
    "orange": {
        "name": "Orange Line (Line 6)",
        "color": "#FF8C00",
        "stations": [
            "Kavi Subhash", "Hemanta Mukherjee", "Subhash Nagar",
            "Ruby Hospital", "Science City", "Chingrighata"
        ]
    }
}

# Build graph for pathfinding
def build_metro_graph():
    graph = {}
    station_lines = {}

    for line_id, line_data in METRO_LINES.items():
        stations = line_data["stations"]
        for i, station in enumerate(stations):
            if station not in graph:
                graph[station] = []
            if station not in station_lines:
                station_lines[station] = []
            station_lines[station].append(line_id)

            if i > 0:
                prev = stations[i - 1]
                graph[station].append({"station": prev, "line": line_id})
            if i < len(stations) - 1:
                nxt = stations[i + 1]
                graph[station].append({"station": nxt, "line": line_id})
    return graph, station_lines

METRO_GRAPH, STATION_LINES = build_metro_graph()

ALL_STATIONS = sorted(list(METRO_GRAPH.keys()))

STATION_DETAILS = {}
for station in ALL_STATIONS:
    lines = STATION_LINES.get(station, [])
    is_interchange = len(lines) > 1
    STATION_DETAILS[station] = {
        "name": station,
        "lines": lines,
        "is_interchange": is_interchange,
        "facilities": ["Ticket Counter", "Smart Card Recharge"],
        "exits": 2 if not is_interchange else 4
    }
    if is_interchange:
        STATION_DETAILS[station]["facilities"].extend(["Escalator", "Elevator", "Waiting Hall"])
    if station in ["Esplanade", "Park Street", "Central", "Sealdah", "Howrah"]:
        STATION_DETAILS[station]["facilities"].extend(["Food Court", "ATM", "Parking"])

# Fare calculation: base Rs 5 + Rs 2 per station
def calculate_fare(num_stations: int) -> float:
    if num_stations <= 1:
        return 5.0
    elif num_stations <= 5:
        return 10.0
    elif num_stations <= 10:
        return 15.0
    elif num_stations <= 15:
        return 20.0
    elif num_stations <= 20:
        return 25.0
    else:
        return 30.0

def find_route(source: str, destination: str):
    if source not in METRO_GRAPH or destination not in METRO_GRAPH:
        return None

    visited = set()
    queue = deque([(source, [source], [None])])
    visited.add(source)

    while queue:
        current, path, lines_used = queue.popleft()
        if current == destination:
            route_segments = []
            current_line = None
            segment_start = path[0]
            for i in range(1, len(path)):
                edge_line = None
                for neighbor in METRO_GRAPH[path[i - 1]]:
                    if neighbor["station"] == path[i]:
                        edge_line = neighbor["line"]
                        break
                if current_line is None:
                    current_line = edge_line
                if edge_line != current_line:
                    route_segments.append({
                        "line": current_line,
                        "line_name": METRO_LINES[current_line]["name"],
                        "color": METRO_LINES[current_line]["color"],
                        "from": segment_start,
                        "to": path[i - 1],
                        "stations": []
                    })
                    segment_start = path[i - 1]
                    current_line = edge_line

            if current_line:
                route_segments.append({
                    "line": current_line,
                    "line_name": METRO_LINES[current_line]["name"],
                    "color": METRO_LINES[current_line]["color"],
                    "from": segment_start,
                    "to": path[-1],
                    "stations": []
                })

            # Fill station lists for each segment
            idx = 0
            for seg in route_segments:
                seg_stations = []
                while idx < len(path):
                    seg_stations.append(path[idx])
                    if path[idx] == seg["to"]:
                        idx += 1
                        break
                    idx += 1
                seg["stations"] = seg_stations

            fare = calculate_fare(len(path) - 1)
            line_changes = len(route_segments) - 1
            est_time = (len(path) - 1) * 3  # 3 min per station

            return {
                "source": source,
                "destination": destination,
                "total_stations": len(path),
                "line_changes": line_changes,
                "estimated_time": est_time,
                "fare": fare,
                "segments": route_segments,
                "path": path
            }

        for neighbor in METRO_GRAPH[current]:
            if neighbor["station"] not in visited:
                visited.add(neighbor["station"])
                queue.append((neighbor["station"], path + [neighbor["station"]], lines_used + [neighbor["line"]]))

    return None

# ======================== AUTH ENDPOINTS ========================

@api_router.post("/auth/register")
async def register(data: AuthRegister, response: Response):
    email = data.email.lower().strip()
    existing = await db.users.find_one({"email": email})
    if existing:
        raise HTTPException(status_code=400, detail="Email already registered")

    hashed = hash_password(data.password)
    user_doc = {
        "email": email,
        "name": data.name,
        "password_hash": hashed,
        "role": "user",
        "metro_card_balance": 0.0,
        "favorites": [],
        "created_at": datetime.now(timezone.utc)
    }
    result = await db.users.insert_one(user_doc)
    user_id = str(result.inserted_id)

    access_token = create_access_token(user_id, email)
    refresh_token = create_refresh_token(user_id)
    response.set_cookie(key="access_token", value=access_token, httponly=True, secure=False, samesite="lax", max_age=3600, path="/")
    response.set_cookie(key="refresh_token", value=refresh_token, httponly=True, secure=False, samesite="lax", max_age=604800, path="/")

    return {"id": user_id, "email": email, "name": data.name, "role": "user", "token": access_token}

@api_router.post("/auth/login")
async def login(data: AuthLogin, request: Request, response: Response):
    email = data.email.lower().strip()
    ip = request.client.host if request.client else "unknown"
    identifier = f"{ip}:{email}"

    attempt = await db.login_attempts.find_one({"identifier": identifier})
    if attempt and attempt.get("count", 0) >= 5:
        lockout_until = attempt.get("locked_until")
        if lockout_until and datetime.now(timezone.utc) < lockout_until:
            raise HTTPException(status_code=429, detail="Too many attempts. Try again in 15 minutes.")
        else:
            await db.login_attempts.delete_one({"identifier": identifier})

    user = await db.users.find_one({"email": email})
    if not user or not verify_password(data.password, user["password_hash"]):
        await db.login_attempts.update_one(
            {"identifier": identifier},
            {"$inc": {"count": 1}, "$set": {"locked_until": datetime.now(timezone.utc) + timedelta(minutes=15)}},
            upsert=True
        )
        raise HTTPException(status_code=401, detail="Invalid credentials")

    await db.login_attempts.delete_one({"identifier": identifier})

    user_id = str(user["_id"])
    access_token = create_access_token(user_id, email)
    refresh_token = create_refresh_token(user_id)
    response.set_cookie(key="access_token", value=access_token, httponly=True, secure=False, samesite="lax", max_age=3600, path="/")
    response.set_cookie(key="refresh_token", value=refresh_token, httponly=True, secure=False, samesite="lax", max_age=604800, path="/")

    return {
        "id": user_id, "email": user["email"], "name": user["name"],
        "role": user.get("role", "user"), "token": access_token,
        "metro_card_balance": user.get("metro_card_balance", 0)
    }

@api_router.post("/auth/logout")
async def logout(response: Response):
    response.delete_cookie("access_token", path="/")
    response.delete_cookie("refresh_token", path="/")
    return {"message": "Logged out"}

@api_router.get("/auth/me")
async def get_me(request: Request):
    user = await get_current_user(request)
    return user

@api_router.post("/auth/refresh")
async def refresh_token(request: Request, response: Response):
    token = request.cookies.get("refresh_token")
    if not token:
        raise HTTPException(status_code=401, detail="No refresh token")
    try:
        payload = jwt.decode(token, get_jwt_secret(), algorithms=[JWT_ALGORITHM])
        if payload.get("type") != "refresh":
            raise HTTPException(status_code=401, detail="Invalid token type")
        user = await db.users.find_one({"_id": ObjectId(payload["sub"])})
        if not user:
            raise HTTPException(status_code=401, detail="User not found")
        access_token = create_access_token(str(user["_id"]), user["email"])
        response.set_cookie(key="access_token", value=access_token, httponly=True, secure=False, samesite="lax", max_age=3600, path="/")
        return {"message": "Token refreshed"}
    except jwt.InvalidTokenError:
        raise HTTPException(status_code=401, detail="Invalid refresh token")

# ======================== METRO DATA ENDPOINTS ========================

@api_router.get("/metro/lines")
async def get_metro_lines():
    lines = []
    for lid, ldata in METRO_LINES.items():
        lines.append({
            "id": lid,
            "name": ldata["name"],
            "color": ldata["color"],
            "station_count": len(ldata["stations"]),
            "stations": ldata["stations"]
        })
    return lines

@api_router.get("/metro/stations")
async def get_all_stations():
    stations = []
    for name in ALL_STATIONS:
        detail = STATION_DETAILS[name]
        stations.append({
            "name": name,
            "lines": detail["lines"],
            "is_interchange": detail["is_interchange"],
            "line_colors": [METRO_LINES[l]["color"] for l in detail["lines"]]
        })
    return stations

@api_router.get("/metro/station/{station_name}")
async def get_station_detail(station_name: str):
    if station_name not in STATION_DETAILS:
        raise HTTPException(status_code=404, detail="Station not found")
    detail = STATION_DETAILS[station_name]
    return {
        **detail,
        "line_colors": [METRO_LINES[l]["color"] for l in detail["lines"]],
        "line_names": [METRO_LINES[l]["name"] for l in detail["lines"]]
    }

@api_router.post("/metro/route")
async def get_route(data: RouteRequest):
    route = find_route(data.source, data.destination)
    if not route:
        raise HTTPException(status_code=404, detail="No route found")
    return route

@api_router.get("/metro/fare")
async def get_fare(source: str, destination: str):
    route = find_route(source, destination)
    if not route:
        raise HTTPException(status_code=404, detail="No route found")
    return {"fare": route["fare"], "stations": route["total_stations"], "time": route["estimated_time"]}

# ======================== TICKET ENDPOINTS ========================

@api_router.post("/tickets/book")
async def book_ticket(data: TicketBookRequest, request: Request):
    user = await get_current_user(request)
    ticket_id = str(uuid.uuid4())[:8].upper()
    total_fare = data.fare * data.num_passengers

    qr_data = json.dumps({
        "ticket_id": ticket_id,
        "source": data.source,
        "destination": data.destination,
        "fare": total_fare,
        "passengers": data.num_passengers,
        "timestamp": datetime.now(timezone.utc).isoformat()
    })
    qr_base64 = generate_qr_base64(qr_data)

    ticket_doc = {
        "ticket_id": ticket_id,
        "user_id": user["_id"],
        "source": data.source,
        "destination": data.destination,
        "fare": total_fare,
        "num_passengers": data.num_passengers,
        "qr_code": qr_base64,
        "status": "active",
        "booked_at": datetime.now(timezone.utc),
        "valid_until": datetime.now(timezone.utc) + timedelta(hours=4)
    }
    await db.tickets.insert_one(ticket_doc)

    return {
        "ticket_id": ticket_id,
        "source": data.source,
        "destination": data.destination,
        "fare": total_fare,
        "num_passengers": data.num_passengers,
        "qr_code": qr_base64,
        "status": "active",
        "booked_at": ticket_doc["booked_at"].isoformat(),
        "valid_until": ticket_doc["valid_until"].isoformat()
    }

@api_router.get("/tickets/my")
async def get_my_tickets(request: Request):
    user = await get_current_user(request)
    tickets = await db.tickets.find(
        {"user_id": user["_id"]},
        {"_id": 0}
    ).sort("booked_at", -1).to_list(50)
    for t in tickets:
        if isinstance(t.get("booked_at"), datetime):
            t["booked_at"] = t["booked_at"].isoformat()
        if isinstance(t.get("valid_until"), datetime):
            t["valid_until"] = t["valid_until"].isoformat()
    return tickets

# ======================== METRO CARD ENDPOINTS ========================

@api_router.get("/card/balance")
async def get_card_balance(request: Request):
    user = await get_current_user(request)
    full_user = await db.users.find_one({"_id": ObjectId(user["_id"])})
    return {
        "balance": full_user.get("metro_card_balance", 0),
        "card_number": f"KMC-{user['_id'][-8:].upper()}"
    }

@api_router.post("/card/topup")
async def topup_card(data: TopUpRequest, request: Request):
    user = await get_current_user(request)
    if data.amount < 10 or data.amount > 5000:
        raise HTTPException(status_code=400, detail="Amount must be between 10 and 5000")

    await db.users.update_one(
        {"_id": ObjectId(user["_id"])},
        {"$inc": {"metro_card_balance": data.amount}}
    )
    txn = {
        "user_id": user["_id"],
        "type": "topup",
        "amount": data.amount,
        "timestamp": datetime.now(timezone.utc)
    }
    await db.card_transactions.insert_one(txn)

    updated = await db.users.find_one({"_id": ObjectId(user["_id"])})
    return {"balance": updated.get("metro_card_balance", 0), "message": f"Rs {data.amount} added successfully"}

@api_router.get("/card/transactions")
async def get_card_transactions(request: Request):
    user = await get_current_user(request)
    txns = await db.card_transactions.find(
        {"user_id": user["_id"]},
        {"_id": 0}
    ).sort("timestamp", -1).to_list(50)
    for t in txns:
        if isinstance(t.get("timestamp"), datetime):
            t["timestamp"] = t["timestamp"].isoformat()
    return txns

@api_router.post("/card/pay")
async def pay_with_card(data: TicketBookRequest, request: Request):
    user = await get_current_user(request)
    full_user = await db.users.find_one({"_id": ObjectId(user["_id"])})
    balance = full_user.get("metro_card_balance", 0)
    total = data.fare * data.num_passengers

    if balance < total:
        raise HTTPException(status_code=400, detail="Insufficient balance")

    await db.users.update_one(
        {"_id": ObjectId(user["_id"])},
        {"$inc": {"metro_card_balance": -total}}
    )

    ticket_id = str(uuid.uuid4())[:8].upper()
    qr_data = json.dumps({"ticket_id": ticket_id, "source": data.source, "destination": data.destination, "fare": total})
    qr_base64 = generate_qr_base64(qr_data)

    ticket_doc = {
        "ticket_id": ticket_id, "user_id": user["_id"],
        "source": data.source, "destination": data.destination,
        "fare": total, "num_passengers": data.num_passengers,
        "qr_code": qr_base64, "status": "active",
        "payment_method": "metro_card",
        "booked_at": datetime.now(timezone.utc),
        "valid_until": datetime.now(timezone.utc) + timedelta(hours=4)
    }
    await db.tickets.insert_one(ticket_doc)

    await db.card_transactions.insert_one({
        "user_id": user["_id"], "type": "payment",
        "amount": -total, "description": f"{data.source} → {data.destination}",
        "timestamp": datetime.now(timezone.utc)
    })

    updated = await db.users.find_one({"_id": ObjectId(user["_id"])})
    return {
        "ticket_id": ticket_id, "qr_code": qr_base64,
        "balance": updated.get("metro_card_balance", 0),
        "fare": total, "source": data.source, "destination": data.destination
    }

# ======================== AI CHATBOT ========================

@api_router.post("/chat")
async def chat_endpoint(data: ChatRequest, request: Request):
    try:
        user = await get_current_user(request)
    except Exception:
        user = None

    from emergentintegrations.llm.chat import LlmChat, UserMessage

    system_msg = f"""You are KolkataMetro AI, an intelligent assistant for the Kolkata Metro system.
You know everything about Kolkata Metro lines:
- Blue Line (Line 1): {', '.join(METRO_LINES['blue']['stations'])}
- Green Line (Line 2): {', '.join(METRO_LINES['green']['stations'])}
- Purple Line (Line 3): {', '.join(METRO_LINES['purple']['stations'])}
- Orange Line (Line 6): {', '.join(METRO_LINES['orange']['stations'])}

Key interchange stations: Esplanade (Blue, Green, Purple), Rabindra Sadan (Blue, Purple), Kavi Subhash (Blue, Orange)

Fare structure: Rs 5 (1 station), Rs 10 (2-5), Rs 15 (6-10), Rs 20 (11-15), Rs 25 (16-20), Rs 30 (21+)
Operating hours: 6:45 AM to 9:45 PM (Mon-Sat), 10:00 AM to 9:45 PM (Sunday)
Frequency: 5-10 minutes during peak, 10-15 minutes off-peak

Be helpful, concise, and provide practical transit advice. Use emojis sparingly."""

    session_id = data.session_id or (user["_id"] if user else str(uuid.uuid4()))

    chat = LlmChat(
        api_key=os.environ.get("EMERGENT_LLM_KEY", ""),
        session_id=f"metro-chat-{session_id}",
        system_message=system_msg
    ).with_model("openai", "gpt-4o-mini")

    # Load recent chat history
    history = await db.chat_history.find(
        {"session_id": session_id}
    ).sort("timestamp", -1).limit(10).to_list(10)
    history.reverse()

    for msg in history:
        if msg["role"] == "user":
            chat.messages.append({"role": "user", "content": msg["content"]})
        else:
            chat.messages.append({"role": "assistant", "content": msg["content"]})

    user_message = UserMessage(text=data.message)
    response_text = await chat.send_message(user_message)

    # Save to history
    now = datetime.now(timezone.utc)
    await db.chat_history.insert_many([
        {"session_id": session_id, "role": "user", "content": data.message, "timestamp": now},
        {"session_id": session_id, "role": "assistant", "content": response_text, "timestamp": now}
    ])

    return {"response": response_text, "session_id": session_id}

# ======================== FAVORITES ========================

@api_router.post("/favorites/add")
async def add_favorite(request: Request):
    user = await get_current_user(request)
    body = await request.json()
    station = body.get("station")
    if not station:
        raise HTTPException(status_code=400, detail="Station required")
    await db.users.update_one(
        {"_id": ObjectId(user["_id"])},
        {"$addToSet": {"favorites": station}}
    )
    return {"message": "Added to favorites"}

@api_router.post("/favorites/remove")
async def remove_favorite(request: Request):
    user = await get_current_user(request)
    body = await request.json()
    station = body.get("station")
    await db.users.update_one(
        {"_id": ObjectId(user["_id"])},
        {"$pull": {"favorites": station}}
    )
    return {"message": "Removed from favorites"}

@api_router.get("/favorites")
async def get_favorites(request: Request):
    user = await get_current_user(request)
    full_user = await db.users.find_one({"_id": ObjectId(user["_id"])})
    return {"favorites": full_user.get("favorites", [])}

# ======================== STARTUP ========================

@app.on_event("startup")
async def startup():
    await db.users.create_index("email", unique=True)
    await db.login_attempts.create_index("identifier")
    await db.tickets.create_index("user_id")
    await db.card_transactions.create_index("user_id")
    await db.chat_history.create_index("session_id")

    # Seed admin
    admin_email = os.environ.get("ADMIN_EMAIL", "admin@kolkatametro.com")
    admin_password = os.environ.get("ADMIN_PASSWORD", "admin123")
    existing = await db.users.find_one({"email": admin_email})
    if not existing:
        await db.users.insert_one({
            "email": admin_email,
            "name": "Admin",
            "password_hash": hash_password(admin_password),
            "role": "admin",
            "metro_card_balance": 500.0,
            "favorites": ["Esplanade", "Park Street", "Howrah"],
            "created_at": datetime.now(timezone.utc)
        })
        logger.info(f"Admin user seeded: {admin_email}")
    elif not verify_password(admin_password, existing["password_hash"]):
        await db.users.update_one(
            {"email": admin_email},
            {"$set": {"password_hash": hash_password(admin_password)}}
        )

    # Write test credentials
    Path("/app/memory").mkdir(exist_ok=True)
    with open("/app/memory/test_credentials.md", "w") as f:
        f.write(f"# Test Credentials\n\n")
        f.write(f"## Admin\n- Email: {admin_email}\n- Password: {admin_password}\n- Role: admin\n\n")
        f.write(f"## Auth Endpoints\n- POST /api/auth/register\n- POST /api/auth/login\n- POST /api/auth/logout\n- GET /api/auth/me\n- POST /api/auth/refresh\n")

    logger.info("Kolkata Metro API started successfully")

app.include_router(api_router)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.on_event("shutdown")
async def shutdown_db_client():
    client.close()
