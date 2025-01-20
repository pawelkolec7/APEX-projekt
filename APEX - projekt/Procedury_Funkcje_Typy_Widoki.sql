--Views
  CREATE OR REPLACE FORCE EDITIONABLE VIEW "PRACOWNICY_DOSTEPNOSC" ("STATUS_PRACOWNIKA", "LICZBA_PRACOWNIKOW") AS 
  SELECT
    CASE
        WHEN SYSDATE BETWEEN u.data_rozpoczecia AND u.data_zakonczenia THEN 'Na urlopie'
        ELSE 'Dost�pni do pracy'
    END AS status_pracownika,
    COUNT(p.id_pracownika) AS liczba_pracownikow
FROM
    pracownicy p
LEFT JOIN
    urlopy u
ON
    p.id_pracownika = u.id_pracownika
AND
    SYSDATE BETWEEN u.data_rozpoczecia AND u.data_zakonczenia
GROUP BY
    CASE
        WHEN SYSDATE BETWEEN u.data_rozpoczecia AND u.data_zakonczenia THEN 'Na urlopie'
        ELSE 'Dost�pni do pracy'
    END;
    
  CREATE OR REPLACE FORCE EDITIONABLE VIEW "PRACOWNICY_ZAMOWIENIA" ("ID_PRACOWNIKA", "IMIE", "NAZWISKO", "ID_ZAMOWIENIA", "DATA_ZLOZENIA", "STATUS", "SPOSOB_DOSTAWY", "KOMENTARZ") AS 
  SELECT
    p.id_pracownika,
    p.imie,
    p.nazwisko,
    z.id_zamowienia,
    z.data_zlozenia,
    z.status,
    z.sposob_dostawy,
    z.komentarz
FROM
    pracownicy p
JOIN
    zamowienia z
ON
    p.id_pracownika = z.id_pracownika
WHERE
    z.status IN ('W trakcie realizacji', 'Z�o�one', 'Przygotowane do wysy�ki');
    
  CREATE OR REPLACE FORCE EDITIONABLE VIEW "WIDOK_TYPY_ZAMOWIEN" ("TYP_ZAMOWIENIA", "LICZBA_ZAMOWIEN") AS 
  SELECT 
    status AS typ_zamowienia, -- Typ zam�wienia
    COUNT(id_zamowienia) AS liczba_zamowien -- Liczba zam�wie�
FROM 
    zamowienia
WHERE 
    status != 'Zako�czone' -- Wykluczenie zam�wie� ze statusem "Zako�czone"
GROUP BY 
    status
ORDER BY 
    liczba_zamowien DESC;
    
--Types
create or replace TYPE produkt_udzial_tab AS TABLE OF produkt_udzial_typ

create or replace TYPE produkt_udzial_typ AS OBJECT (
    produkt_id NUMBER,
    produkt_nazwa VARCHAR2(100),
    udzial NUMBER
)

--Procedures
create or replace PROCEDURE bestseller_statystyki(
    p_data_od IN DATE, -- Data pocz�tkowa
    p_data_do IN DATE, -- Data ko�cowa
    p_bestseller OUT VARCHAR2, -- Bestseller
    p_bestseller_ilosc OUT NUMBER, -- Ilo�� sprzedanych sztuk bestsellera
    p_ilosc_zamowien OUT NUMBER -- Liczba wszystkich zam�wie�
)
IS
BEGIN
    -- Bestseller i ilo�� sprzedanych sztuk
    BEGIN
        SELECT p.nazwa, SUM(i.zamawiana_ilosc)
        INTO p_bestseller, p_bestseller_ilosc
        FROM zamowienia z
        JOIN ilosc i ON z.id_zamowienia = i.id_zamowienia
        JOIN produkty p ON i.id_produktu = p.id_produktu
        WHERE z.data_zlozenia BETWEEN p_data_od AND p_data_do
        GROUP BY p.nazwa
        ORDER BY SUM(i.zamawiana_ilosc) DESC
        FETCH FIRST 1 ROWS ONLY;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            -- Je�li brak wynik�w, przypisz domy�lne warto�ci
            p_bestseller := 'Brak danych';
            p_bestseller_ilosc := 0;
    END;

    -- Liczba wszystkich zam�wie�
    SELECT COUNT(*)
    INTO p_ilosc_zamowien
    FROM zamowienia z
    WHERE z.data_zlozenia BETWEEN p_data_od AND p_data_do;

    -- Wy�wietlenie wynik�w (opcjonalnie)
    DBMS_OUTPUT.PUT_LINE('Bestseller: ' || p_bestseller);
    DBMS_OUTPUT.PUT_LINE('Ilo�� sprzedanych sztuk bestsellera: ' || p_bestseller_ilosc);
    DBMS_OUTPUT.PUT_LINE('Liczba wszystkich zam�wie�: ' || p_ilosc_zamowien);
END;
/

--Functions
create or replace FUNCTION IS_NUMBER (p_value IN VARCHAR2)
RETURN NUMBER IS
BEGIN
    IF REGEXP_LIKE(p_value, '^\d+$') THEN
        RETURN 1; -- Je�li jest liczb�, zwr�� 1
    ELSE
        RETURN 0; -- Je�li nie jest liczb�, zwr�� 0
    END IF;
END IS_NUMBER;
/

create or replace FUNCTION produkt_udzial_sprzedazy (
    p_data_od IN DATE,        -- Data pocz�tkowa
    p_data_do IN DATE         -- Data ko�cowa
) RETURN produkt_udzial_tab PIPELINED
IS
    v_sprzedaz_produktu NUMBER := 0;
    v_suma_sprzedazy NUMBER := 0;
BEGIN
    -- Oblicz ca�kowit� sum� sprzeda�y w danym okresie
    SELECT NVL(SUM(i.zamawiana_ilosc), 0)
    INTO v_suma_sprzedazy
    FROM ilosc i
    JOIN zamowienia z ON i.id_zamowienia = z.id_zamowienia
    WHERE z.data_zlozenia BETWEEN p_data_od AND p_data_do;

    -- Iteruj po produktach i oblicz ich udzia� procentowy
    FOR produkt IN (
        SELECT 
            p.id_produktu AS produkt_id,
            p.nazwa AS produkt_nazwa,
            NVL(SUM(i.zamawiana_ilosc), 0) AS sprzedaz_produktu
        FROM produkty p
        LEFT JOIN ilosc i ON p.id_produktu = i.id_produktu
        LEFT JOIN zamowienia z ON i.id_zamowienia = z.id_zamowienia
        WHERE z.data_zlozenia BETWEEN p_data_od AND p_data_do
        GROUP BY p.id_produktu, p.nazwa
    ) LOOP
        -- Emituj wiersz dla ka�dego produktu
        PIPE ROW(produkt_udzial_typ(
            produkt.produkt_id,
            produkt.produkt_nazwa,
            CASE 
                WHEN v_suma_sprzedazy > 0 THEN ROUND((produkt.sprzedaz_produktu / v_suma_sprzedazy) * 100, 2)
                ELSE 0
            END
        ));
    END LOOP;

    RETURN;
END;
/