<img width="1916" height="906" alt="Screenshot 2026-03-06 155715" src="https://github.com/user-attachments/assets/6a45a3ea-1e58-43e3-8328-b04302aeaedd" /># Mini POS – Stock & Purchase 

This project is a Mini Retail Procurement and Stock Management System.
It focuses on managing Purchase Orders, Goods Receipt (GRN), stock updates, and price tracking.

## 🎯 Objective
- Create and manage Purchase Orders (PO)
- Receive goods using GRN and update inventory
- Maintain real-time stock dashboard
- Track item price changes with history
- Provide latest selling price for sales usage
## 🛠️ Tech Stack
Backend: .NET 8 Web API

Frontend: Flutter

Database: SQL Server

Authentication: JWT

API Testing: Swagger

CI: Basic pipeline integration

## 👥 User Roles
- Admin/User
  - Create Purchase Orders
  - Enter GRN
  - Update pricing
  - View stock & price history

## 📱 Features
### 🧾 Purchase Order
- Create PO with multiple items
- Approve PO before receiving goods
- Track order status (Draft / Approved / Closed)
### 📦 GRN (Goods Receipt Note)
- Receive items against PO
- Validate received quantity
- Automatically update stock
### 📊 Stock Dashboard
- View available stock (Qty on Hand)
- Filter/search items
- Identify low or zero stock
### 💰 Price History
- Track purchase and selling price changes
- Maintain historical records
- Apply pricing rule:
- Selling Price = Purchase Cost + (Purchase Cost × Margin%)
### 🗄️ Database Design (Main Tables)
Items

Suppliers

PurchaseOrderHeader & Lines

GRNHeader & Lines

StockLedger

StockOnHand

ItemPriceHistory

Users
## 🔐 Non-Functional Features
- JWT Authentication
- Secure APIs
- Swagger Documentation
- Audit Fields (Created/Modified)
- Clean Architecture
## 🚀 How to Run the Project
🔹 Backend (.NET API)
Clone the repository

Open in Visual Studio

Configure SQL Server connection

Run migrations / database script

Run the API

Open Swagger

🔹 Frontend (Flutter)

Open project in VS Code / Android Studio

Run flutter pub get

Connect to API URL

Run app


## 📷 Screenshots

Dashboard

<img width="1916" height="906" alt="Screenshot 2026-03-06 155715" src="https://github.com/user-attachments/assets/8c2e5a70-511f-4c60-aca4-7d4cfb6b10f5" />







