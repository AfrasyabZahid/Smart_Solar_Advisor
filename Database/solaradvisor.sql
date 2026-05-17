CREATE DATABASE SmartSolarDB;
GO

USE SmartSolarDB;
GO

CREATE TABLE [User] (
    user_id INT PRIMARY KEY IDENTITY(1,1),
    name VARCHAR(100),
    email VARCHAR(150) UNIQUE,
    password VARCHAR(255),
    created_at DATETIME DEFAULT GETDATE()
);


CREATE TABLE Solar_Assessment (
    assessment_id INT PRIMARY KEY IDENTITY(1,1),
    daily_units FLOAT,
    roof_area FLOAT,
    load_shedding_hours INT,
    created_at DATETIME DEFAULT GETDATE(),
    user_id INT,
    FOREIGN KEY (user_id) REFERENCES [User](user_id)
);


CREATE TABLE Solar_Recommendation (
    recommendation_id INT PRIMARY KEY IDENTITY(1,1),
    system_capacity FLOAT,
    estimated_cost FLOAT,
    created_at DATETIME DEFAULT GETDATE(),
    assessment_id INT,
    FOREIGN KEY (assessment_id) REFERENCES Solar_Assessment(assessment_id)
);


CREATE TABLE Recommendation_History (
    history_id INT PRIMARY KEY IDENTITY(1,1),
    user_id INT,
    recommendation_id INT,
    generated_at DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (user_id) REFERENCES [User](user_id),
    FOREIGN KEY (recommendation_id) REFERENCES Solar_Recommendation(recommendation_id)
);