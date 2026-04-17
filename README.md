# Mini POS – Stock & Purchase 

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
Admin/User
Create Purchase Orders
Enter GRN
Update pricing
View stock & price history
## 🔄 Core Workflow
Purchase Order → Approval → GRN → Stock Update → Price Update
## 📱 Features
### 🧾 Purchase Order
Create PO with multiple items
Approve PO before receiving goods
Track order status (Draft / Approved / Closed)
### 📦 GRN (Goods Receipt Note)
Receive items against PO
Validate received quantity
Automatically update stock
### 📊 Stock Dashboard
View available stock (Qty on Hand)
Filter/search items
Identify low or zero stock
### 💰 Price History
Track purchase and selling price changes
Maintain historical records
Apply pricing rule:
Selling Price = Purchase Cost + (Purchase Cost × Margin%)
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
JWT Authentication
Secure APIs
Swagger Documentation
Audit Fields (Created/Modified)
Clean Architecture
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



