CREATE TABLE Country (
    country_location TEXT,
    iso_code TEXT NOT NULL,
    last_observation_date DATE,
    source_name TEXT,
    source_website TEXT,
    PRIMARY KEY (iso_code)
);

CREATE TABLE Country_Vaccine (
    iso_code TEXT NOT NULL,
    vaccine TEXT NOT NULL,
    PRIMARY KEY (iso_code, vaccine),
    FOREIGN KEY (iso_code) REFERENCES Country(iso_code)
);


CREATE TABLE State (
    state_location TEXT NOT NULL,
    iso_code TEXT NOT NULL,  
    PRIMARY KEY (state_location, iso_code),
    FOREIGN KEY (iso_code) REFERENCES Country(iso_code)
);


CREATE TABLE Manufacturer_Vaccination (
    iso_code TEXT NOT NULL,
    date DATE NOT NULL,
    vaccine TEXT NOT NULL,
    total_vaccinations INTEGER,
    PRIMARY KEY (iso_code, date, vaccine),
    FOREIGN KEY (iso_code) REFERENCES Country(iso_code)
);

CREATE TABLE AgeGroup_Vaccination (
    iso_code TEXT NOT NULL,
    date DATE NOT NULL,
    age_group TEXT NOT NULL,
    people_vaccinated_per_hundred INTEGER,
    people_fully_vaccinated_per_hundred INTEGER,
    people_with_booster_per_hundred INTEGER,
    PRIMARY KEY (iso_code, date, age_group),
    FOREIGN KEY (iso_code) REFERENCES Country(iso_code)
);


CREATE TABLE State_Vaccination_Metrics (
    state_location TEXT NOT NULL,
    iso_code TEXT NOT NULL,
    date DATE NOT NULL,
    total_vaccinations INTEGER,
    daily_vaccinations_raw INTEGER,
    daily_vaccinations INTEGER,
    people_vaccinated INTEGER,
    people_fully_vaccinated INTEGER,
    total_distributed INTEGER,
    total_boosters INTEGER,
    PRIMARY KEY (state_location, iso_code, date),
    FOREIGN KEY (state_location, iso_code) REFERENCES State(state_location, iso_code)
);

CREATE TABLE State_Calculated_Metrics (
    state_location TEXT NOT NULL,
    iso_code TEXT NOT NULL,
    date DATE,
    total_vaccinations_per_hundred REAL,
    daily_vaccinations_per_million REAL,
    people_vaccinated_per_hundred REAL,
    people_fully_vaccinated_per_hundred REAL,
    total_distributed_per_hundred REAL,
    share_doses_used REAL,
    total_boosters_per_hundred REAL,
    PRIMARY KEY (state_location, iso_code, date),
    FOREIGN KEY (state_location, iso_code) REFERENCES State(state_location, iso_code)
);


CREATE TABLE Country_Vaccination_Metrics (
    iso_code TEXT NOT NULL,
    date DATE NOT NULL,
    total_vaccinations INTEGER,
    daily_vaccinations_raw INTEGER,
    daily_vaccinations INTEGER,
    people_vaccinated INTEGER,
    people_fully_vaccinated INTEGER,
    total_boosters INTEGER,
    daily_people_vaccinated INTEGER,
    PRIMARY KEY (iso_code, date),
    FOREIGN KEY (iso_code) REFERENCES Country(iso_code)
);

CREATE TABLE Country_Calculated_Metrics (
    iso_code TEXT NOT NULL,
    date DATE NOT NULL,
    total_vaccinations_per_hundred REAL,
    daily_vaccinations_per_million REAL,
    people_vaccinated_per_hundred REAL,
    people_fully_vaccinated_per_hundred REAL,
    total_boosters_per_hundred REAL,
    daily_people_vaccinated_per_hundred REAL,
    PRIMARY KEY (iso_code, date),
    FOREIGN KEY (iso_code) REFERENCES Country(iso_code)
);

CREATE TABLE Country_Source (
    iso_code TEXT NOT NULL,
    date DATE NOT NULL,
    source_url TEXT,
    PRIMARY KEY (iso_code, date)
    FOREIGN KEY (iso_code, date) REFERENCES Country_Vaccination_Metrics(iso_code, date)
);
