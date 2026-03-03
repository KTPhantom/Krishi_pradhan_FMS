import mysql, { Pool } from 'mysql2/promise';
import { Config } from '../config/Config';

export class Database {
    private static instance: Database;
    private pool: Pool;

    private constructor() {
        this.pool = mysql.createPool({
            host: Config.DB.HOST,
            user: Config.DB.USER,
            password: Config.DB.PASS,
            database: Config.DB.NAME,
            dateStrings: true,
            waitForConnections: true,
            connectionLimit: Config.DB.LIMIT,
            queueLimit: 0
        });

        // Test connection
        this.pool.getConnection()
            .then(conn => {
                console.log(Config.MESSAGES.DB_CONNECTED);
                conn.release();
            })
            .catch(err => {
                console.error(Config.MESSAGES.DB_ERROR, err.message);
            });
    }

    public static getInstance(): Database {
        if (!Database.instance) {
            Database.instance = new Database();
        }
        return Database.instance;
    }

    public getPool(): Pool {
        return this.pool;
    }
}
