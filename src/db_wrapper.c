#include <sqlite3.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

static sqlite3 *db = NULL;

#define ST_OK               0
#define ST_NOT_FOUND        1
#define ST_INSUFFICIENT     2
#define ST_ALREADY_EXISTS   3
#define ST_DB_ERROR         9


static void cobol_to_cstr(char *dest, const char *src, int len, int max) {
    int n = len;
    if (n >= max) n = max - 1;
    memcpy(dest, src, n);
    while (n > 0 && dest[n - 1] == ' ') n--;
    dest[n] = '\0';
}

void db_open(char *path, int *path_len, int *status) {
    char cpath[256];
    cobol_to_cstr(cpath, path, *path_len, sizeof(cpath));

    if (sqlite3_open(cpath, &db) != SQLITE_OK) {
        *status = ST_DB_ERROR;
        return;
    }

    const char *ddl =
        "CREATE TABLE IF NOT EXISTS accounts ("
        "  acc_id  TEXT PRIMARY KEY,"
        "  name    TEXT NOT NULL,"
        "  balance REAL NOT NULL"
        ");";

    char *errmsg = NULL;
    if (sqlite3_exec(db, ddl, NULL, NULL, &errmsg) != SQLITE_OK) {
        fprintf(stderr, "Error creando esquema: %s\n", errmsg);
        sqlite3_free(errmsg);
        *status = ST_DB_ERROR;
        return;
    }

    *status = ST_OK;
}

void db_create_account(char *acc_id, int *id_len,
                        char *name, int *name_len,
                        double *balance, int *status) {
    char cid[32], cname[128];
    cobol_to_cstr(cid, acc_id, *id_len, sizeof(cid));
    cobol_to_cstr(cname, name, *name_len, sizeof(cname));

    sqlite3_stmt *stmt;
    sqlite3_prepare_v2(db, "SELECT 1 FROM accounts WHERE acc_id = ?", -1, &stmt, NULL);
    sqlite3_bind_text(stmt, 1, cid, -1, SQLITE_STATIC);
    if (sqlite3_step(stmt) == SQLITE_ROW) {
        sqlite3_finalize(stmt);
        *status = ST_ALREADY_EXISTS;
        return;
    }
    sqlite3_finalize(stmt);

    sqlite3_prepare_v2(db,
        "INSERT INTO accounts (acc_id, name, balance) VALUES (?, ?, ?)",
        -1, &stmt, NULL);
    sqlite3_bind_text(stmt, 1, cid, -1, SQLITE_STATIC);
    sqlite3_bind_text(stmt, 2, cname, -1, SQLITE_STATIC);
    sqlite3_bind_double(stmt, 3, *balance);

    *status = (sqlite3_step(stmt) == SQLITE_DONE) ? ST_OK : ST_DB_ERROR;
    sqlite3_finalize(stmt);
}

void db_get_balance(char *acc_id, int *id_len, double *balance, int *status) {
    char cid[32];
    cobol_to_cstr(cid, acc_id, *id_len, sizeof(cid));

    sqlite3_stmt *stmt;
    sqlite3_prepare_v2(db, "SELECT balance FROM accounts WHERE acc_id = ?", -1, &stmt, NULL);
    sqlite3_bind_text(stmt, 1, cid, -1, SQLITE_STATIC);

    if (sqlite3_step(stmt) == SQLITE_ROW) {
        *balance = sqlite3_column_double(stmt, 0);
        *status = ST_OK;
    } else {
        *status = ST_NOT_FOUND;
    }
    sqlite3_finalize(stmt);
}

void db_update_balance(char *acc_id, int *id_len, double *delta, int *status) {
    char cid[32];
    cobol_to_cstr(cid, acc_id, *id_len, sizeof(cid));

    double current;
    int st;
    db_get_balance(acc_id, id_len, &current, &st);
    if (st != ST_OK) { *status = ST_NOT_FOUND; return; }

    double new_balance = current + *delta;
    if (new_balance < 0.0) { *status = ST_INSUFFICIENT; return; }

    sqlite3_stmt *stmt;
    sqlite3_prepare_v2(db, "UPDATE accounts SET balance = ? WHERE acc_id = ?", -1, &stmt, NULL);
    sqlite3_bind_double(stmt, 1, new_balance);
    sqlite3_bind_text(stmt, 2, cid, -1, SQLITE_STATIC);

    *status = (sqlite3_step(stmt) == SQLITE_DONE) ? ST_OK : ST_DB_ERROR;
    sqlite3_finalize(stmt);
}

void db_list_accounts(void) {
    sqlite3_stmt *stmt;
    sqlite3_prepare_v2(db, "SELECT acc_id, name, balance FROM accounts ORDER BY acc_id", -1, &stmt, NULL);

    printf("\n%-10s %-25s %15s\n", "CUENTA", "TITULAR", "SALDO");
    printf("--------------------------------------------------------\n");
    while (sqlite3_step(stmt) == SQLITE_ROW) {
        printf("%-10s %-25s %15.2f\n",
               sqlite3_column_text(stmt, 0),
               sqlite3_column_text(stmt, 1),
               sqlite3_column_double(stmt, 2));
    }
    printf("--------------------------------------------------------\n");
    sqlite3_finalize(stmt);
}

void db_close(void) {
    if (db) {
        sqlite3_close(db);
        db = NULL;
    }
}