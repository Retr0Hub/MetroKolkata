# Kolkata Metro App - Product Requirements Document

## Overview
A comprehensive Kolkata Metro transit mobile application built with Expo React Native (frontend) and FastAPI (backend) with MongoDB database.

## Features

### Core Features
- **Route Finder**: BFS-based pathfinding across all 4 metro lines with line change detection
- **Metro Map**: All 4 Kolkata Metro lines (Blue, Green, Purple, Orange) with 44+ stations
- **Fare Calculator**: Distance-based fare calculation (Rs 5-30)
- **Station Details**: Facilities, exits, interchange info for each station

### Smart Features
- **AI Chatbot**: GPT-4o-mini powered metro assistant for route queries, timings, fares
- **QR Ticket Booking**: Book tickets with auto-generated QR codes (base64 PNG)
- **Virtual Metro Card**: NFC-ready digital transit card with balance management
- **Top-Up System**: Add Rs 10-5000 to metro card with transaction history

### Authentication
- JWT-based auth with bcrypt password hashing
- Register/Login/Logout flows
- Brute force protection (5 attempts = 15 min lockout)
- Favorites management for stations

### Metro Lines Data
| Line | Name | Stations | Route |
|------|------|----------|-------|
| Blue (Line 1) | Blue Line | 22 | Dakshineswar ↔ Kavi Subhash |
| Green (Line 2) | Green Line | 11 | Salt Lake Sector V ↔ Howrah Maidan |
| Purple (Line 3) | Purple Line | 9 | Joka ↔ Esplanade |
| Orange (Line 6) | Orange Line | 6 | Kavi Subhash ↔ Chingrighata |

### Interchange Stations
- **Esplanade**: Blue, Green, Purple
- **Rabindra Sadan**: Blue, Purple
- **Kavi Subhash**: Blue, Orange

## Tech Stack
- **Frontend**: Expo SDK 54, React Native, Expo Router (file-based)
- **Backend**: FastAPI, Motor (async MongoDB), PyJWT, bcrypt
- **Database**: MongoDB
- **AI**: GPT-4o-mini via Emergent LLM Key
- **QR Generation**: qrcode + Pillow (Python)

## API Endpoints
- Auth: `/api/auth/login`, `/api/auth/register`, `/api/auth/logout`, `/api/auth/me`
- Metro: `/api/metro/lines`, `/api/metro/stations`, `/api/metro/route`, `/api/metro/fare`
- Tickets: `/api/tickets/book`, `/api/tickets/my`
- Card: `/api/card/balance`, `/api/card/topup`, `/api/card/transactions`, `/api/card/pay`
- Chat: `/api/chat`
- Favorites: `/api/favorites`, `/api/favorites/add`, `/api/favorites/remove`
