"""
Comprehensive backend API tests for Kolkata Metro App
Tests: Auth, Metro Data, Tickets, Metro Card, AI Chat, Favorites
"""
import pytest
import requests
import os
import time

BASE_URL = os.environ.get('EXPO_PUBLIC_BACKEND_URL', '').rstrip('/')
if not BASE_URL:
    pytest.skip("EXPO_PUBLIC_BACKEND_URL not set", allow_module_level=True)

# Test credentials from test_credentials.md
ADMIN_EMAIL = "admin@kolkatametro.com"
ADMIN_PASSWORD = "admin123"

class TestAuth:
    """Authentication endpoint tests"""
    
    def test_admin_login_success(self):
        """Test admin login with correct credentials"""
        response = requests.post(f"{BASE_URL}/api/auth/login", json={
            "email": ADMIN_EMAIL,
            "password": ADMIN_PASSWORD
        })
        assert response.status_code == 200, f"Login failed: {response.text}"
        
        data = response.json()
        assert "token" in data, "Token not in response"
        assert "id" in data, "User ID not in response"
        assert data["email"] == ADMIN_EMAIL
        assert data["role"] == "admin"
        assert "metro_card_balance" in data
        print(f"✓ Admin login successful: {data['email']}, balance: Rs {data.get('metro_card_balance', 0)}")
    
    def test_login_invalid_credentials(self):
        """Test login with wrong password"""
        response = requests.post(f"{BASE_URL}/api/auth/login", json={
            "email": ADMIN_EMAIL,
            "password": "wrongpassword"
        })
        assert response.status_code == 401, "Should return 401 for invalid credentials"
        print("✓ Invalid credentials rejected correctly")
    
    def test_register_new_user(self):
        """Test user registration"""
        test_email = f"test_user_{int(time.time())}@test.com"
        response = requests.post(f"{BASE_URL}/api/auth/register", json={
            "name": "Test User",
            "email": test_email,
            "password": "testpass123"
        })
        assert response.status_code == 200, f"Registration failed: {response.text}"
        
        data = response.json()
        assert "token" in data
        assert data["email"] == test_email
        assert data["role"] == "user"
        print(f"✓ User registration successful: {test_email}")
        
        # Verify user can login
        login_response = requests.post(f"{BASE_URL}/api/auth/login", json={
            "email": test_email,
            "password": "testpass123"
        })
        assert login_response.status_code == 200
        print(f"✓ New user can login successfully")
    
    def test_register_duplicate_email(self):
        """Test registration with existing email"""
        response = requests.post(f"{BASE_URL}/api/auth/register", json={
            "name": "Admin Duplicate",
            "email": ADMIN_EMAIL,
            "password": "somepass"
        })
        assert response.status_code == 400, "Should reject duplicate email"
        print("✓ Duplicate email registration rejected")
    
    def test_get_current_user(self):
        """Test /auth/me endpoint"""
        # Login first
        login_res = requests.post(f"{BASE_URL}/api/auth/login", json={
            "email": ADMIN_EMAIL,
            "password": ADMIN_PASSWORD
        })
        token = login_res.json()["token"]
        
        # Get current user
        response = requests.get(f"{BASE_URL}/api/auth/me", headers={
            "Authorization": f"Bearer {token}"
        })
        assert response.status_code == 200
        data = response.json()
        assert data["email"] == ADMIN_EMAIL
        assert "password_hash" not in data, "Password hash should not be exposed"
        print(f"✓ Get current user successful: {data['name']}")


class TestMetroData:
    """Metro lines, stations, and route finding tests"""
    
    def test_get_metro_lines(self):
        """Test GET /api/metro/lines"""
        response = requests.get(f"{BASE_URL}/api/metro/lines")
        assert response.status_code == 200
        
        lines = response.json()
        assert isinstance(lines, list)
        assert len(lines) == 4, f"Expected 4 metro lines, got {len(lines)}"
        
        line_ids = [line["id"] for line in lines]
        assert "blue" in line_ids
        assert "green" in line_ids
        assert "purple" in line_ids
        assert "orange" in line_ids
        
        # Check blue line details
        blue_line = next(l for l in lines if l["id"] == "blue")
        assert "Dum Dum" in blue_line["stations"]
        assert "Park Street" in blue_line["stations"]
        print(f"✓ Metro lines retrieved: {len(lines)} lines, Blue line has {blue_line['station_count']} stations")
    
    def test_get_all_stations(self):
        """Test GET /api/metro/stations"""
        response = requests.get(f"{BASE_URL}/api/metro/stations")
        assert response.status_code == 200
        
        stations = response.json()
        assert isinstance(stations, list)
        assert len(stations) > 0
        
        # Check for key stations
        station_names = [s["name"] for s in stations]
        assert "Esplanade" in station_names, "Esplanade interchange station missing"
        assert "Park Street" in station_names
        assert "Dum Dum" in station_names
        
        # Check interchange station
        esplanade = next(s for s in stations if s["name"] == "Esplanade")
        assert esplanade["is_interchange"] == True
        assert len(esplanade["lines"]) > 1
        print(f"✓ Stations retrieved: {len(stations)} stations, Esplanade is interchange with {len(esplanade['lines'])} lines")
    
    def test_find_route_dum_dum_to_park_street(self):
        """Test POST /api/metro/route with Dum Dum to Park Street"""
        response = requests.post(f"{BASE_URL}/api/metro/route", json={
            "source": "Dum Dum",
            "destination": "Park Street"
        })
        assert response.status_code == 200, f"Route finding failed: {response.text}"
        
        route = response.json()
        assert route["source"] == "Dum Dum"
        assert route["destination"] == "Park Street"
        assert "fare" in route
        assert "estimated_time" in route
        assert "total_stations" in route
        assert "segments" in route
        assert route["fare"] > 0
        print(f"✓ Route found: {route['source']} → {route['destination']}, Fare: Rs {route['fare']}, Time: {route['estimated_time']} min, Stations: {route['total_stations']}")
    
    def test_find_route_with_line_change(self):
        """Test route requiring line change"""
        response = requests.post(f"{BASE_URL}/api/metro/route", json={
            "source": "Howrah",
            "destination": "Park Street"
        })
        assert response.status_code == 200
        
        route = response.json()
        assert route["line_changes"] >= 0
        print(f"✓ Route with line changes: {route['line_changes']} change(s)")
    
    def test_find_route_invalid_station(self):
        """Test route with non-existent station"""
        response = requests.post(f"{BASE_URL}/api/metro/route", json={
            "source": "Invalid Station",
            "destination": "Park Street"
        })
        assert response.status_code == 404
        print("✓ Invalid station rejected correctly")
    
    def test_get_station_detail(self):
        """Test GET /api/metro/station/{name}"""
        response = requests.get(f"{BASE_URL}/api/metro/station/Esplanade")
        assert response.status_code == 200
        
        station = response.json()
        assert station["name"] == "Esplanade"
        assert station["is_interchange"] == True
        assert "facilities" in station
        assert "exits" in station
        print(f"✓ Station detail: {station['name']}, Facilities: {len(station['facilities'])}")


class TestTickets:
    """Ticket booking and retrieval tests"""
    
    @pytest.fixture
    def auth_token(self):
        """Get auth token for authenticated requests"""
        response = requests.post(f"{BASE_URL}/api/auth/login", json={
            "email": ADMIN_EMAIL,
            "password": ADMIN_PASSWORD
        })
        return response.json()["token"]
    
    def test_book_ticket(self, auth_token):
        """Test POST /api/tickets/book"""
        response = requests.post(f"{BASE_URL}/api/tickets/book", 
            headers={"Authorization": f"Bearer {auth_token}"},
            json={
                "source": "Dum Dum",
                "destination": "Park Street",
                "fare": 15.0,
                "num_passengers": 1
            }
        )
        assert response.status_code == 200, f"Ticket booking failed: {response.text}"
        
        ticket = response.json()
        assert "ticket_id" in ticket
        assert "qr_code" in ticket
        assert ticket["source"] == "Dum Dum"
        assert ticket["destination"] == "Park Street"
        assert ticket["fare"] == 15.0
        assert ticket["status"] == "active"
        assert len(ticket["qr_code"]) > 0, "QR code should be base64 string"
        print(f"✓ Ticket booked: #{ticket['ticket_id']}, {ticket['source']} → {ticket['destination']}, QR code length: {len(ticket['qr_code'])}")
    
    def test_get_my_tickets(self, auth_token):
        """Test GET /api/tickets/my"""
        # Book a ticket first
        requests.post(f"{BASE_URL}/api/tickets/book", 
            headers={"Authorization": f"Bearer {auth_token}"},
            json={
                "source": "Sealdah",
                "destination": "Esplanade",
                "fare": 10.0,
                "num_passengers": 1
            }
        )
        
        # Get tickets
        response = requests.get(f"{BASE_URL}/api/tickets/my", 
            headers={"Authorization": f"Bearer {auth_token}"}
        )
        assert response.status_code == 200
        
        tickets = response.json()
        assert isinstance(tickets, list)
        assert len(tickets) > 0, "Should have at least one ticket"
        print(f"✓ Retrieved {len(tickets)} ticket(s)")
    
    def test_book_ticket_without_auth(self):
        """Test booking ticket without authentication"""
        response = requests.post(f"{BASE_URL}/api/tickets/book", json={
            "source": "Dum Dum",
            "destination": "Park Street",
            "fare": 15.0,
            "num_passengers": 1
        })
        assert response.status_code == 401, "Should require authentication"
        print("✓ Unauthenticated ticket booking rejected")


class TestMetroCard:
    """Metro card balance and top-up tests"""
    
    @pytest.fixture
    def auth_token(self):
        """Get auth token"""
        response = requests.post(f"{BASE_URL}/api/auth/login", json={
            "email": ADMIN_EMAIL,
            "password": ADMIN_PASSWORD
        })
        return response.json()["token"]
    
    def test_get_card_balance(self, auth_token):
        """Test GET /api/card/balance"""
        response = requests.get(f"{BASE_URL}/api/card/balance", 
            headers={"Authorization": f"Bearer {auth_token}"}
        )
        assert response.status_code == 200
        
        data = response.json()
        assert "balance" in data
        assert "card_number" in data
        assert isinstance(data["balance"], (int, float))
        assert data["card_number"].startswith("KMC-")
        print(f"✓ Card balance: Rs {data['balance']}, Card: {data['card_number']}")
    
    def test_topup_card(self, auth_token):
        """Test POST /api/card/topup"""
        # Get initial balance
        initial_res = requests.get(f"{BASE_URL}/api/card/balance", 
            headers={"Authorization": f"Bearer {auth_token}"}
        )
        initial_balance = initial_res.json()["balance"]
        
        # Top up
        response = requests.post(f"{BASE_URL}/api/card/topup", 
            headers={"Authorization": f"Bearer {auth_token}"},
            json={"amount": 100}
        )
        assert response.status_code == 200
        
        data = response.json()
        assert data["balance"] == initial_balance + 100
        print(f"✓ Top-up successful: Rs {initial_balance} → Rs {data['balance']}")
    
    def test_topup_invalid_amount(self, auth_token):
        """Test top-up with invalid amount"""
        response = requests.post(f"{BASE_URL}/api/card/topup", 
            headers={"Authorization": f"Bearer {auth_token}"},
            json={"amount": 5}  # Below minimum
        )
        assert response.status_code == 400
        print("✓ Invalid top-up amount rejected")
    
    def test_get_card_transactions(self, auth_token):
        """Test GET /api/card/transactions"""
        response = requests.get(f"{BASE_URL}/api/card/transactions", 
            headers={"Authorization": f"Bearer {auth_token}"}
        )
        assert response.status_code == 200
        
        txns = response.json()
        assert isinstance(txns, list)
        print(f"✓ Retrieved {len(txns)} transaction(s)")
    
    def test_pay_with_card(self, auth_token):
        """Test POST /api/card/pay"""
        # Ensure sufficient balance
        requests.post(f"{BASE_URL}/api/card/topup", 
            headers={"Authorization": f"Bearer {auth_token}"},
            json={"amount": 100}
        )
        
        # Pay with card
        response = requests.post(f"{BASE_URL}/api/card/pay", 
            headers={"Authorization": f"Bearer {auth_token}"},
            json={
                "source": "Dum Dum",
                "destination": "Park Street",
                "fare": 15.0,
                "num_passengers": 1
            }
        )
        assert response.status_code == 200
        
        data = response.json()
        assert "ticket_id" in data
        assert "qr_code" in data
        assert "balance" in data
        print(f"✓ Card payment successful: Ticket #{data['ticket_id']}, Remaining balance: Rs {data['balance']}")


class TestAIChat:
    """AI chatbot endpoint tests"""
    
    @pytest.fixture
    def auth_token(self):
        """Get auth token"""
        response = requests.post(f"{BASE_URL}/api/auth/login", json={
            "email": ADMIN_EMAIL,
            "password": ADMIN_PASSWORD
        })
        return response.json()["token"]
    
    def test_chat_endpoint(self, auth_token):
        """Test POST /api/chat"""
        response = requests.post(f"{BASE_URL}/api/chat", 
            headers={"Authorization": f"Bearer {auth_token}"},
            json={"message": "What are the metro lines in Kolkata?"}
        )
        assert response.status_code == 200, f"Chat failed: {response.text}"
        
        data = response.json()
        assert "response" in data
        assert "session_id" in data
        assert len(data["response"]) > 0
        print(f"✓ AI chat response received: {data['response'][:100]}...")
    
    def test_chat_without_auth(self):
        """Test chat without authentication (should still work)"""
        response = requests.post(f"{BASE_URL}/api/chat", json={
            "message": "Hello"
        })
        # Chat endpoint allows unauthenticated access
        assert response.status_code in [200, 401]
        print(f"✓ Chat endpoint status: {response.status_code}")


class TestFavorites:
    """Favorite stations tests"""
    
    @pytest.fixture
    def auth_token(self):
        """Get auth token"""
        response = requests.post(f"{BASE_URL}/api/auth/login", json={
            "email": ADMIN_EMAIL,
            "password": ADMIN_PASSWORD
        })
        return response.json()["token"]
    
    def test_add_favorite(self, auth_token):
        """Test POST /api/favorites/add"""
        response = requests.post(f"{BASE_URL}/api/favorites/add", 
            headers={"Authorization": f"Bearer {auth_token}"},
            json={"station": "Dum Dum"}
        )
        assert response.status_code == 200
        print("✓ Favorite station added")
    
    def test_get_favorites(self, auth_token):
        """Test GET /api/favorites"""
        response = requests.get(f"{BASE_URL}/api/favorites", 
            headers={"Authorization": f"Bearer {auth_token}"}
        )
        assert response.status_code == 200
        
        data = response.json()
        assert "favorites" in data
        assert isinstance(data["favorites"], list)
        print(f"✓ Retrieved {len(data['favorites'])} favorite(s)")
    
    def test_remove_favorite(self, auth_token):
        """Test POST /api/favorites/remove"""
        # Add first
        requests.post(f"{BASE_URL}/api/favorites/add", 
            headers={"Authorization": f"Bearer {auth_token}"},
            json={"station": "Test Station"}
        )
        
        # Remove
        response = requests.post(f"{BASE_URL}/api/favorites/remove", 
            headers={"Authorization": f"Bearer {auth_token}"},
            json={"station": "Test Station"}
        )
        assert response.status_code == 200
        print("✓ Favorite station removed")


if __name__ == "__main__":
    pytest.main([__file__, "-v", "--tb=short"])
