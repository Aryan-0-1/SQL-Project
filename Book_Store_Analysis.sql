-- Create Database
CREATE DATABASE OnlineBookstore;

-- Switch to the database
\c OnlineBookstore;

-- Creating Table for Books Information in Database
DROP TABLE IF EXISTS Books;
CREATE TABLE Books(
    Book_ID INTEGER PRIMARY KEY,
    Title VARCHAR(100),
    Author VARCHAR(100),
    Genre VARCHAR(50),
    Published_Year INTEGER,
    Price NUMERIC(10, 2),
    Stock INTEGER
    );

-- Adding Books Information in Database
COPY Books(Book_ID, Title, Author, Genre, Published_Year, Price, Stock) 
FROM 'Books.csv' 
CSV HEADER;

-- Creating Table for Customers Information in Database
DROP TABLE IF EXISTS Customers;
CREATE TABLE Customers(
    Customer_ID INTEGER PRIMARY KEY,
    Name VARCHAR(100),
    Email VARCHAR(100),
    Phone INTEGER,
    City VARCHAR(50),
    Country VARCHAR(50)
    );

-- Adding Customers Information in Database
COPY Customers(Customer_ID, Name, Email, Phone, City, Country) 
FROM 'Customers.csv' 
CSV HEADER;

-- Creating Table for Orders Information in Database
DROP TABLE IF EXISTS Orders;
CREATE TABLE Orders(
    Order_ID INTEGER PRIMARY KEY,
    Book_ID INTEGER,
    Customer_ID INTEGER,
    Order_Date DATE,
    Quantity INTEGER,
    Total_Amount NUMERIC(10, 2)
    );


-- Adding Orders Information in Database
COPY Orders(Order_ID, Customer_ID, Book_ID, Order_Date, Quantity, Total_Amount) 
FROM 'Orders.csv' 
CSV HEADER;

-- Basic Queries


-- 1) Retrieve all books in the "Fiction" genre:
SELECT * FROM Books WHERE Genre = "Fiction";

-- 2) Find books published after the year 1950:
SELECT * FROM Books WHERE Published_Year > 1950
ORDER BY Published_Year ASC;

-- 3) List all customers from the Canada:
SELECT * FROM Customers WHERE Country = "Canada";

-- 4) Show orders placed in November 2023:
SELECT * FROM Orders 
WHERE strftime('%Y-%m', Order_Date) == "2023-11";

-- OR
-- SELECT * FROM Orders 
-- WHERE order_date BETWEEN '2023-11-01' AND '2023-11-30';

-- 5) Retrieve the total stock of books available:
SELECT SUM(Stock) AS Total_Stock FROM Books;

-- 6) Find the details of the most expensive book:
SELECT * FROM Books 
WHERE Price = (SELECT MAX(Price) FROM Books);

-- 7) Show all customers who ordered more than 1 quantity of a book:
SELECT C.* FROM Customers C
LEFT JOIN Orders O
ON O.Customer_ID = C.Customer_ID
WHERE O.Quantity > 1;

-- 8) Retrieve all orders where the total amount exceeds $20:
SELECT * FROM Orders WHERE Total_Amount > 20;

-- 9) List all genres available in the Books table:
SELECT DISTINCT(Genre) FROM Books;

-- 10) Find the book with the lowest stock:
SELECT * FROM Books WHERE Stock = (SELECT MIN(Stock) FROM Books);

-- 11) Calculate the total revenue generated from all orders:
SELECT SUM(Total_Amount) AS 'Total Revenue' FROM Orders;


-- Advance Questions :


-- 1) Retrieve the total number of books sold for each genre:
SELECT B.Genre, SUM(O.Quantity) AS 'Total Books Sold' FROM Books B
JOIN Orders O
ON B.Book_ID = O.Book_ID
GROUP BY B.Genre;

-- 2) Find the average price of books in the "Fantasy" genre:
SELECT Genre,AVG(Price) AS 'Average Price' FROM Books 
WHERE Genre = "Fantasy";

-- 3) List customers who have placed at least 2 orders:
WITH count_table AS(
                        SELECT Customer_ID ,COUNT(Customer_ID) AS 'Number_of_Orders' FROM Orders 
                        GROUP BY Customer_ID
                    )
    
SELECT T.Customer_ID, C.Name, T.Number_of_Orders FROM Customers C
RIGHT JOIN (
                SELECT Customer_ID, Number_of_Orders FROM count_table
                WHERE Number_of_Orders >= 2
            ) T
ON C.Customer_ID = T.Customer_ID;

-- OR
-- SELECT o.customer_id, c.name, COUNT(o.Order_id) AS ORDER_COUNT
-- FROM orders o
-- JOIN customers c ON o.customer_id=c.customer_id
-- GROUP BY o.customer_id, c.name
-- HAVING COUNT(Order_id) >=2;

--4) Find the most frequently ordered book:
WITH count_table AS(
                        SELECT Book_ID ,COUNT(Order_ID) AS 'Number_of_Orders' FROM Orders 
                        GROUP BY Book_ID   
                    )
    
SELECT B.*,T.Number_of_Orders FROM Books B
RIGHT JOIN (
                SELECT Book_ID,Number_of_Orders FROM count_table
                WHERE Number_of_Orders == (SELECT MAX(Number_of_Orders) FROM count_table)
            ) T
ON B.Book_ID = T.Book_ID;

-- 5) Show the top 3 most expensive books of 'Fantasy' Genre:
SELECT * FROM Books WHERE Genre == 'Fantasy'
ORDER BY Price DESC LIMIT 3;

-- 6) Retrieve the total quantity of books sold by each author:
SELECT B.Author,SUM(O.Quantity) AS 'Total_Quantity_of_Books_Sold' FROM Books B
JOIN Orders O
ON B.Book_ID = O.Book_ID
GROUP BY B.Author;

-- 7) List the cities where customers who spent over $30 are located:
WITH spent_table AS (
                        SELECT Customer_ID, SUM(Total_Amount) AS 'Total_Spent' FROM Orders
                        GROUP BY Customer_ID
                    )

SELECT DISTINCT(City) FROM Customers
WHERE Customer_ID IN (SELECT Customer_ID FROM spent_table WHERE Total_Spent > 30 );

-- 8) Find the customer who spent the most on orders:
WITH spent_table AS (
                        SELECT Customer_ID, SUM(Total_Amount) AS 'Total_Spent' FROM Orders
                        GROUP BY Customer_ID
                    )
                
SELECT * FROM Customers C
RIGHT JOIN (SELECT Customer_ID, MAX(Total_Spent) FROM spent_table) T
ON C.Customer_ID = T.Customer_ID;

--9) Calculate the stock remaining after fulfilling all orders:
WITH books_ordered AS (
                        SELECT Book_ID, SUM(Quantity) AS 'Total_Books_Ordered' FROM Orders
                        GROUP BY Book_ID
                      )
                         
SELECT B.*, COALESCE((B.Stock - O.Total_Books_Ordered),B.Stock) AS 'Remaning_Stock' FROM Books B
LEFT JOIN (SELECT * FROM books_ordered) O
ON B.Book_ID = O.Book_ID;