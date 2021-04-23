SET SERVEROUTPUT ON;

DROP SEQUENCE SECUENCIA_AUDITORIA;
DROP TABLE AUDITORIA;

--REQUISITO 1:
CREATE TABLE AUDITORIA(
    ID_AUDITORIA NUMBER (4),
    NOMBRE VARCHAR2 (20),
    SUCESO VARCHAR2 (20), 
    USUARIO VARCHAR2 (30), 
    FECHA DATE
    );
-- Secuencia para crear un registro en la tabla auditoria.
CREATE SEQUENCE SECUENCIA_AUDITORIA START WITH 1 MAXVALUE 999 INCREMENT BY 1; 

-- Procedimiento que guarda los registros creados en la tabla auditoria.
CREATE OR REPLACE PROCEDURE REGISTRAR_AUDITORIA (NOMBRE VARCHAR2, SUCESO VARCHAR2, USUARIO VARCHAR2, FECHA DATE) IS    
BEGIN
    INSERT INTO AUDITORIA (ID_AUDITORIA, NOMBRE, SUCESO, USUARIO, FECHA)
    VALUES (SECUENCIA_AUDITORIA.NEXTVAL, NOMBRE , SUCESO, USUARIO, FECHA);
END;
/




-- Disparador que inserta, actualiza o borra los coches (es decir guardas los cambios realizados en la tabla auditoria).
CREATE OR REPLACE TRIGGER CONTROL_COCHE
    AFTER INSERT OR UPDATE OR DELETE ON COCHE
    FOR EACH ROW
DECLARE
    V_SUCESO VARCHAR2(50);

/*Asigna un valor a la variable según hayamos insertado, borrado o actualizado.*/
BEGIN
    IF INSERTING THEN
		V_SUCESO := 'Inserción';
    ELSIF DELETING THEN
		V_SUCESO := 'Borrado';
    ELSIF UPDATING THEN
		V_SUCESO := 'Actualización';
    END IF;
    REGISTRAR_AUDITORIA('COCHE', V_SUCESO, USER, SYSDATE);
END;
/

-- Disparador que inserta, actualiza o borra los concesionarios (es decir guardas los cambios realizados en la tabla auditoria).
CREATE OR REPLACE TRIGGER CONTROL_CONCESIONARIO
    AFTER INSERT OR UPDATE OR DELETE ON CONCESIONARIO
    FOR EACH ROW
DECLARE
    V_SUCESO VARCHAR2(50);

/*Asigna un valor a la variable según hayamos insertado, borrado o actualizado.*/
BEGIN
    IF INSERTING THEN
		V_SUCESO := 'Inserción';
    ELSIF DELETING THEN
		V_SUCESO := 'Borrado';
    ELSIF UPDATING THEN
		V_SUCESO := 'Actualización';
    END IF;
    REGISTRAR_AUDITORIA('CONCESIONARIO', V_SUCESO, USER, SYSDATE);
END;
/

-- Disparador que inserta, actualiza o borra las personas (es decir guardas los cambios realizados en la tabla auditoria).
CREATE OR REPLACE TRIGGER CONTROL_PERSONA
AFTER INSERT OR DELETE OR UPDATE ON PERSONA
FOR EACH ROW
DECLARE 
    V_SUCESO VARCHAR2(50);
    
/*Asigna un valor a la variable según hayamos insertado, borrado o actualizado.*/

BEGIN
    IF INSERTING THEN
		V_SUCESO:='Inserción';
    ELSIF DELETING THEN
		V_SUCESO:='Borrado';
    ELSIF UPDATING THEN
		V_SUCESO:='Actualización';
    END IF;
    REGISTRAR_AUDITORIA('PERSONA', V_SUCESO, USER, SYSDATE);
END;
/

--REQUISITO 2

-- Función que dice si existe el coche según su número de bastidor.
CREATE OR REPLACE FUNCTION EXISTE_COCHE (NUM_BASTIDOR_COCHE VARCHAR2)
    RETURN BOOLEAN IS
    NUM_BASTIDOR VARCHAR2 (20);
    V_NUM_BASTIDOR VARCHAR2(20);
BEGIN
    SELECT NUM_BASTIDOR INTO V_NUM_BASTIDOR FROM COCHE WHERE NUM_BASTIDOR=NUM_BASTIDOR_COCHE;
	/*Si se ha encontrado el número de bastidor y coincide, se devuelve verdadero.*/
        RETURN V_NUM_BASTIDOR = NUM_BASTIDOR;
    /*Si no se encuentra el número de bastidor, se devuelve falso.*/
    EXCEPTION WHEN NO_DATA_FOUND THEN
        RETURN FALSE;
END;
/



-- Procedimiento que muestra la información detallada de un coche
CREATE OR REPLACE PROCEDURE CONSULTAR_COCHES(NUM_BASTIDOR NUMBER) IS
    /*Uso un cursor para obtener los datos que voy a mostrar del coche.*/
    CURSOR CUR IS SELECT C.NUM_BASTIDOR, C.MARCA_COCHE, C.TIPO_COCHE, C.COLOR, C.MATRICULA
        FROM COCHE C ;
    
    V_NUM_BASTIDOR CUR%ROWTYPE;
    V_TOTAL NUMBER;
BEGIN
    V_TOTAL:=0;
    OPEN CUR;
    -- El FETCH me permite recuperar los datos de la primera fila 
    FETCH CUR INTO V_NUM_BASTIDOR;  
            DBMS_OUTPUT.PUT_LINE ('****************************************************');
            DBMS_OUTPUT.PUT_LINE ('NUMERO DE BASTIDOR: ' || V_NUM_BASTIDOR.NUM_BASTIDOR);
            DBMS_OUTPUT.PUT_LINE ('MARCA DEL COCHE: ' || V_NUM_BASTIDOR.MARCA_COCHE);
            DBMS_OUTPUT.PUT_LINE ('TIPO DE COCHE: ' || V_NUM_BASTIDOR.TIPO_COCHE);
            DBMS_OUTPUT.PUT_LINE ('COLOR DEL COCHE: ' || V_NUM_BASTIDOR.COLOR);
            DBMS_OUTPUT.PUT_LINE ('MATRICULA: ' || V_NUM_BASTIDOR.MATRICULA);
            DBMS_OUTPUT.PUT_LINE ('');
    CLOSE CUR;
END;
/

--REQUISITO 3

-- Función que muestra el dni de la persona según su nombre.
CREATE OR REPLACE FUNCTION CONSULTAR_DNI_PERSONA(NOMBRE_PERSONA VARCHAR2) RETURN NUMBER IS
    DNI_PERSONA VARCHAR2(9);
    
BEGIN
    SELECT DNI INTO DNI_PERSONA FROM PERSONA WHERE NOMBRE_PERSONA=NOMBRE;
        RETURN DNI_PERSONA;
    EXCEPTION WHEN NO_DATA_FOUND THEN
        RETURN -1;
END;
/

--REQUISITO 4

-- Función que dice si existe la persona según su dnii.
CREATE OR REPLACE FUNCTION EXIXTE_PERSONA(DNI_PERSONA VARCHAR2)
RETURN BOOLEAN IS
    V_DNI VARCHAR2(9);
BEGIN
    SELECT DNI INTO V_DNI FROM PERSONA WHERE DNI=DNI_PERSONA;
    /*Si se ha encontrado el dni de la persona y coincide, se devuelve verdadero.*/
        RETURN TRUE;
    /*Si no se encuentra el dni de la persona, se devuelve falso.*/
    EXCEPTION WHEN NO_DATA_FOUND THEN
        RETURN FALSE;
END;
/

--REQUISITO 5

-- Disparador de fila que evalua el formato del codigo postal.
CREATE OR REPLACE TRIGGER FORMATO_COD_POSTAL
BEFORE INSERT OR UPDATE OF COD_POSTAL ON CONCESIONARIO
FOR EACH ROW

/*Si el codigo postal tiene este formato es correcto*/
/*Si no tiene ese formato da error*/
BEGIN
    IF NOT (REGEXP_LIKE(:NEW.COD_POSTAL, '[0-9][0-9][0-9][0-9][0-9]'))THEN 
    RAISE_APPLICATION_ERROR(-20100, 'ERROR');
    END IF;
END;
/

--REQUISITO 6

--Disparador de instrucción que evalua a las horas que nose pueden introducir coches.
CREATE OR REPLACE TRIGGER HORA_COCHE
    BEFORE INSERT ON COCHE
    BEGIN
        IF (TO_CHAR(SYSDATE,'HH24') IN ('1', '2', '3', '4', '5', '6', '7')) THEN
            RAISE_APPLICATION_ERROR (-20100,'No se puede añadir ningun coche a esas horas porque los concesionarios estan cerrados.');
    END IF;
END;
/