create table Stanowiska(
	nazwa_stanowiska VARCHAR(100) primary key,
	placa_min NUMERIC(10, 2) not null,
    placa_max NUMERIC(10, 2) not null
);

create table Pracownicy(
	id_pracownika NUMBER(10) GENERATED ALWAYS AS IDENTITY primary key,
	imie VARCHAR(100) not null,
	nazwisko VARCHAR(100) not null,
	telefon VARCHAR(100),
	email VARCHAR(100),
	stanowisko VARCHAR(100) references Stanowiska(nazwa_stanowiska) ON DELETE CASCADE, 
	placa NUMBER(10,2) not null,
	premia NUMBER(10,2) not null
);

create table Urlopy(
	id_urlopu NUMBER(10) GENERATED ALWAYS AS IDENTITY primary key,
	id_pracownika NUMBER(10) references Pracownicy(id_pracownika) ON DELETE CASCADE,
	data_rozpoczecia DATE not null,
	data_zakonczenia DATE not null,
	typ_urlopu VARCHAR(100)
);

create table Adresy(
	id_adresu NUMBER(10) GENERATED ALWAYS AS IDENTITY primary key,
	kod_pocztowy VARCHAR(100) not null,
	miejscowosc VARCHAR(100) not null,
	ulica VARCHAR(100),
	nr_domu VARCHAR(100) not null,
	nr_mieszkania VARCHAR(100),
	kraj VARCHAR(100) not null
);

create table Klienci(
	id_klienta NUMBER(10) GENERATED ALWAYS AS IDENTITY primary key,
	imie VARCHAR(100) not null,
	nazwisko VARCHAR(100) not null,
	telefon VARCHAR(100),
	email VARCHAR(100),
	nr_karty_rabatowej VARCHAR(100)
);

create table Zamowienia(
	id_zamowienia NUMBER(10) GENERATED ALWAYS AS IDENTITY primary key,
	id_klienta NUMBER(10) references Klienci(id_klienta) ON DELETE CASCADE,
	id_adresu NUMBER(10) references Adresy(id_adresu) ON DELETE CASCADE,
	id_pracownika NUMBER(10) references Pracownicy(id_pracownika) ON DELETE CASCADE,
	data_zlozenia DATE not null,
	sposob_dostawy VARCHAR(100) not null,
	status VARCHAR(100) not null,
	komentarz VARCHAR(100)
);

create table Kategorie(
	nazwa VARCHAR(100) primary key,
	opis VARCHAR(100)
);

create table Producent(
	nazwa VARCHAR(100) primary key,
	opis VARCHAR(100),
	telefon VARCHAR(100),
	email VARCHAR(100)
);

create table Produkty(
	id_produktu NUMBER(10) GENERATED ALWAYS AS IDENTITY primary key,
	nazwa VARCHAR(100) not null,
	kategoria VARCHAR(100) references Kategorie(nazwa) ON DELETE CASCADE,
	opis VARCHAR(100),
	producent VARCHAR(100) references Producent(nazwa) ON DELETE CASCADE
);

create table Ilosc(
	zamawiana_ilosc NUMBER(10) not null,
	id_produktu NUMBER(10) references Produkty(id_produktu) ON DELETE CASCADE,
	id_zamowienia NUMBER(10) references Zamowienia(id_zamowienia) ON DELETE CASCADE
);