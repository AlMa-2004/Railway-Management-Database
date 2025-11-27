# Railway Company Management Database

Railway Company Management database with a Flask interface for CRUD operations on entities, created for the **Databases** university course.

## Motivation
I chose to create a database project for managing railway operations because this topic has become an important part of my weekly routine. As a frequent user of railway transport services, I have always been curious to understand what happens behind the scenes to ensure the smooth functioning of this complex system.

---

## Software Used
- **Database Management System (DBMS):** MySQL  
- **Database Design & Management:** MySQL Workbench  
- **Backend & Application Logic:** Python with Flask framework  
- **Frontend:** HTML and CSS  
- **Database Connection Library:** `mysql.connector`  

This setup allows the web interface to communicate with the MySQL database, providing a user-friendly interface for managing trains, routes, employees, stations, tickets, and other operational data.

---

## Interface

The project includes a **web-based interface** (found in `\Interface`) built with **Python** and **Flask**, which allows users to interact with the database.
Through this interface, users can:

- Add, update, and delete records for trains, routes, wagons, employees, stations, and tickets.
- See specific query results (catered towards the initial tasks given with the project).

---

## Installation & Running

To run this project locally, you need:

1. **Python** installed (3.7+ recommended)  
2. **Flask** installed
3. **MySQL** installed and running locally  
4. The database schema set up (use the provided `init_script.sql`)

## Steps

1. Set up your MySQL database and create the schema.  
2. Update the Flask app configuration (`config.py`) with your database credentials.  
3. Install required Python packages:
```bash
pip install -r requirements.txt
```
4. Run the flask development server with:
```bash
python app.py
```
5. Access the interface in a browser, at `http://localhost:5000`.

--- 

## Notes
- The project is **fully in Romanian**. A complete English translation is **not yet available**.
