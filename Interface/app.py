from flask import Flask, render_template, request, redirect, url_for, flash
import mysql.connector
from mysql.connector import Error, errorcode
import os
from dotenv import load_dotenv

app = Flask(__name__)
app.secret_key = '1234'  

load_dotenv()

def get_db_connection():
    try:
        conexiune = mysql.connector.connect(
            host=os.getenv("DB_HOST"),
            user=os.getenv("DB_USER"),
            password=os.getenv("DB_PASSWORD"),
            database=os.getenv("DB_NAME")
        )
        if conexiune.is_connected():
            return conexiune
    except Exception as e:
        return None



@app.route('/')
def home():
    return render_template('homepage.html')



@app.route('/listare')
def listare():
    conexiune = get_db_connection()
    if conexiune:
        cursor = conexiune.cursor()
        cursor.execute('show tables')
   
        tables = [table[0] for table in cursor.fetchall()] 
        
        tables = [table for table in tables if table != 'apartine_de']
        
        cursor.close()
        conexiune.close()
    else:
        tables = []

    return render_template('listare.html', tables=tables)
@app.route('/tabel/<table_name>')
def show_table_data(table_name):
    sort_column = request.args.get('sort_column', None)
    sort_order = request.args.get('sort_order', 'asc')

    connection = get_db_connection()
    if connection:
        cursor = connection.cursor(dictionary=True)
        try:
            cursor.execute(f"DESCRIBE {table_name}")
            columns = [col['Field'] for col in cursor.fetchall()]

            query = f"SELECT * FROM {table_name}"
            if sort_column and sort_column in columns:
                query += f" ORDER BY {sort_column} {sort_order.upper()}"

            cursor.execute(query)
            rows = cursor.fetchall()

        except mysql.connector.Error as e:
            print(f"Database Error: {e}")
            flash(f"Database Error: {e}", 'error')
            return redirect(url_for('home'))
        finally:
            cursor.close()
            connection.close()
    else:
        flash("Database connection failed!", 'error')
        return redirect(url_for('home'))

    return render_template(
        'tabel_sort.html',
        table_name=table_name,
        rows=rows,
        columns=columns,
        sort_column=sort_column,
        sort_order=sort_order
    )
@app.route('/tabel/apartine_de')
def show_apartine_de():
    sort_column = request.args.get('sort_column', None)
    sort_order = request.args.get('sort_order', 'asc')

    connection = get_db_connection()
    if connection:
        cursor = connection.cursor(dictionary=True)
        try:
            cursor.execute("DESCRIBE apartine_de")
            columns = [col['Field'] for col in cursor.fetchall()]

            query = "SELECT * FROM apartine_de"
            
            if sort_column and sort_column in columns:
                query += f" ORDER BY {sort_column} {sort_order.upper()}"
            
            cursor.execute(query)
            rows = cursor.fetchall()

        except mysql.connector.Error as e:
            print(f"Database Error: {e}")
            flash(f"Database Error: {e}", 'error')
            return redirect(url_for('listare'))
        finally:
            cursor.close()
            connection.close()
    else:
        flash("Database connection failed!", 'error')
        return redirect(url_for('listare'))

    return render_template(
        'apartine_de_sort.html',
        table_name="apartine_de",
        rows=rows,
        columns=columns,
        sort_column=sort_column,
        sort_order=sort_order
    )

@app.route('/tabel/apartine_de/edit/<pk1>/<pk2>', methods=['GET', 'POST'])
def edit_apartine_de(pk1, pk2):
    conexiune = get_db_connection()
    cursor = conexiune.cursor(dictionary=True)

    try:
        cursor.execute("describe apartine_de")
        columns = [col['Field'] for col in cursor.fetchall()]

        if request.method == 'POST':
            updated_values = {key: request.form[key] for key in request.form}

            set_clause = ", ".join([f"{key} = %s" for key in updated_values.keys()])
            update_query = f"""
                update apartine_de
                set {set_clause}
                where id_ruta = %s and nr_ordine = %s
            """

            try:
                cursor.execute(update_query, (*updated_values.values(), pk1, pk2))
                conexiune.commit()
                print("Intrare actualizata cu succes!")

            except mysql.connector.Error as e:
                print(f"Eroare: {e}")
                print(f"Cod eroare: {e.errno}")
                print(f"Mesaj eroare: {e.msg}")

                if e.errno == errorcode.ER_DUP_ENTRY:
                    error_message = "Intrare duplicat in tabel!"
                elif e.errno == 1288:
                    error_message = "Modificarile nu sunt permise!"
                elif e.errno == 1265:
                    error_message = "Valoarea introdusa nu se regaseste in lista de valori permise!"
                elif e.errno == 1366:
                    error_message = "Valoarea introdusa nu poate fi nula!"
                elif e.errno == 3819:
                    error_message = "O constrangere a fost incalcata!"
                elif e.errno == 1451:
                    error_message = "Modificarea nu este permisa! Intrari ale altor tabele sunt dependente de aceasta intrare!"
                elif e.errno == 1452:
                    error_message = "Constrangere de cheie straina incalcata! Valoarea introdusa nu exista in tabelul referentiat!"
                else:
                    error_message = f"Ceva nu a functionat! Eroare:{e.errno}"

                return render_template('eroare.html', error_message=error_message)

            except Exception as e:
                print(f"Ceva nu a functionat!!: {e}")
                return render_template('eroare.html', error_message="Ceva nu a functionat!!")

            return redirect(url_for('show_apartine_de'))

        cursor.execute("select * from apartine_de where id_ruta = %s and nr_ordine = %s", (pk1, pk2))
        row = cursor.fetchone()

    except mysql.connector.Error as e:
        print(f"Eroare: {e}")
        print(f"Cod eroare: {e.errno}")
        print(f"Mesaj eroare: {e.msg}")
        return redirect(url_for('show_apartine_de'))

    except Exception as e:
        print(f"Ceva nu a functionat!!: {e}")
        return redirect(url_for('show_apartine_de'))

    finally:
        cursor.close()
        conexiune.close()

    return render_template('editare.html', table_name='apartine_de', row=row, columns=columns)



@app.route('/tabel/apartine_de/delete/<pk1>/<pk2>', methods=['POST'])
def delete_apartine_de(pk1, pk2):
    conexiune = get_db_connection()
    cursor = conexiune.cursor()

    try:

        delete_query = "delete from apartine_de where id_ruta = %s and nr_ordine = %s"
        cursor.execute(delete_query, (pk1, pk2))
        conexiune.commit()
        print("Intrare stearsa cu succes!")

    except mysql.connector.Error as e:
        print(f"Eroare: {e}")

    finally:
        cursor.close()
        conexiune.close()

    return redirect(url_for('show_apartine_de'))



@app.route('/tabel/<table_name>/edit/<pk>', methods=['GET', 'POST'])
def edit_entry(table_name, pk):
    conexiune = get_db_connection()
    cursor = conexiune.cursor(dictionary=True)

    cursor.execute(f"describe {table_name}")
    columns = [col['Field'] for col in cursor.fetchall()]

    exclude_columns = ['reducere', 'pret'] 
    columns_to_display = [col for col in columns if col not in exclude_columns]

    if request.method == 'POST':
        updated_values = {key: request.form[key] for key in request.form if key not in exclude_columns}

        print(f"Updated values: {updated_values}")

        set_clause = ", ".join([f"{key} = %s" for key in updated_values.keys()])
        update_query = f"update {table_name} set {set_clause} where {columns[0]} = %s"

        print(f"SQL query: {update_query}")

        try:
            cursor.execute(update_query, (*updated_values.values(), pk))
            conexiune.commit()
            print("Intrarea actualizata cu succes!")

        except mysql.connector.Error as e:
            print(f"Eroare: {e}")
            print(f"Cod eroare: {e.errno}")
            print(f"Mesaj cod: {e.msg}")

            if e.errno == errorcode.ER_DUP_ENTRY:
                error_message = "Intrare duplicat in tabel!"
            elif e.errno == 1288:
                error_message = "Modificarile nu sunt permise!"
            elif e.errno == 1265:
                error_message = "Valoarea introdusa nu se regaseste in lista de valori permise!"
            elif e.errno == 1366:
                error_message = "Valoarea introdusa nu poate fi nula!"
            elif e.errno == 3819:
                error_message = "O constrangere a fost incalcata!"
            elif e.errno == 1451:
                 error_message = "Modificarea nu este permisa! Intrari ale altor tabele sunt dependente de aceasta intrare!"
            elif e.errno == 1452:
                error_message = "Constrangere de cheie straina incalcata! Valoarea introdusa nu exista in tabelul referentiat!"
            else:
                error_message = f"Ceva nu a functionat! Eroare:{e.errno}"
            
            return render_template('eroare.html', error_message=error_message)
            
        except Exception as e:
            print(f"Ceva nu a functionat!!: {e}")
            return render_template('eroare.html', error_message="Ceva nu a functionat!!")

        return redirect(url_for('show_table_data', table_name=table_name))

    cursor.execute(f"select * from {table_name} where {columns[0]} = %s", (pk,))
    row = cursor.fetchone()

    cursor.close()
    conexiune.close()

    return render_template('editare.html', table_name=table_name, row=row, columns=columns_to_display)



@app.route('/tabel/<table_name>/delete/<pk>', methods=['POST'])
def delete_entry(table_name, pk):
    conexiune = get_db_connection()
    cursor = conexiune.cursor()

    try:
        cursor.execute(f"show keys from {table_name} where Key_name = 'PRIMARY'")
        primary_key = cursor.fetchone()

        primary_key_column = primary_key[4]
        print(f"Primary key for {table_name}: {primary_key_column}")

        delete_query = f"delete from {table_name} where {primary_key_column} = %s"

        cursor.execute(delete_query, (pk,))
        conexiune.commit()
        print("Intrare stearsa cu succes!")

    except mysql.connector.Error as e:
        print(f"Eroare: {e}")
        
        if e.errno == 1451:
            error_message = "Intrarea nu poatea fi stearsa! Alte intrari din alte tabele sunt dependente de ea!"
        else: 
            error_message = f"Ceva nu a functionat! Eroare:{e.errno}"

        return render_template('eroare.html', error_message=error_message)

    except Exception as e:
        print(f"Ceva nu a functionat!!: {e}")

    finally:
        cursor.close()
        conexiune.close()

    return redirect(url_for('show_table_data', table_name=table_name))



@app.route('/cerere-complexa')
def cerere_complexa():
    conexiune = get_db_connection()
    if conexiune:
        cursor = conexiune.cursor(dictionary=True)
        try:
            query = """
                select distinct p.nume, p.prenume, 
                timestampdiff(minute, c.timp_plecare, c.timp_sosire) - r.durata_estimata as intarziere
                from ruta r
                join cursa c on r.id_ruta = c.id_ruta
                join bilet b on c.id_cursa = b.id_cursa
                join pasager p on b.cnp = p.cnp
                where c.id_cursa = 6 and p.statut = 'Student';
            """
            cursor.execute(query)
            result = cursor.fetchall()
            cursor.close()
            conexiune.close()

            return render_template('cerere_complexa.html', result=result)

        except mysql.connector.Error as e:
            print(f"Eroare: {e}")
            return redirect(url_for('home'))

    print("Conexiunea nu a reusit!")
    return redirect(url_for('home'))



@app.route('/functii-grup')
def functii_grup():
    conexiune = get_db_connection()
    if conexiune:
        cursor =  conexiune.cursor(dictionary=True)
        try:
            query="""
                select t.cod_uic, count(v.cod_uic) as Numar_Vagoane
                from vagon v 
                join tren t on v.cod_uic_tren=t.cod_uic
                group by t.cod_uic
                having count(v.cod_uic) = 3;"""
            cursor.execute(query)
            result=cursor.fetchall()
            cursor.close()
            conexiune.close()
            return render_template('functii_grup.html', result=result)
        
        except mysql.connector.Error as e:
            print(f"Eroare: {e}")
        return redirect(url_for('home'))

    print("Conexiunea nu a reusit!")
    return redirect(url_for('home'))



if __name__ == '__main__':
    app.run(debug=True)

