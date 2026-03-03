import { Request, Response } from 'express';
import { Database } from '../database/Database';
import { v4 as uuidv4 } from 'uuid';
import bcrypt from 'bcryptjs';

export class SystemController {

    public setupDatabase = async (req: Request, res: Response) => {
        console.log('🚀 Database Initialization...');
        const pool = Database.getInstance().getPool();
        const conn = await pool.getConnection();

        try {
            await conn.beginTransaction();

            // 1. Users
            await conn.query(`
                CREATE TABLE IF NOT EXISTS Users (
                    id VARCHAR(36) PRIMARY KEY,
                    username VARCHAR(255) NOT NULL UNIQUE,
                    password VARCHAR(255) NOT NULL,
                    role VARCHAR(50) NOT NULL DEFAULT 'worker'
                )
            `);

            // 2. Fields
            await conn.query(`
                CREATE TABLE IF NOT EXISTS Fields (
                    id VARCHAR(36) PRIMARY KEY,
                    name VARCHAR(255) NOT NULL,
                    location VARCHAR(255) DEFAULT '',
                    size_acres FLOAT DEFAULT 0,
                    kml_file_name VARCHAR(255),
                    kml_content TEXT,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )
            `);

            // 3. Crop Types
            await conn.query(`
                CREATE TABLE IF NOT EXISTS CropTypes (
                    id VARCHAR(36) PRIMARY KEY,
                    name VARCHAR(50) NOT NULL UNIQUE
                )
            `);

            // Seed crop types
            const defaultCrops = [
                'wheat', 'rice', 'corn', 'cotton', 'sugarcane', 'soybean', 'groundnut',
                'tomato', 'potato', 'onion', 'brinjal', 'chilli', 'okra', 'cabbage', 'cauliflower',
                'mango', 'banana', 'guava', 'pomegranate', 'lemon'
            ];
            for (const crop of defaultCrops) {
                const [rows]: any = await conn.query('SELECT id FROM CropTypes WHERE name = ?', [crop]);
                if (rows.length === 0) {
                    await conn.query('INSERT INTO CropTypes (id, name) VALUES (?, ?)', [uuidv4(), crop]);
                }
            }

            // 4. Crops
            await conn.query(`
                CREATE TABLE IF NOT EXISTS Crops (
                    id VARCHAR(36) PRIMARY KEY,
                    field_id VARCHAR(36) NOT NULL,
                    name VARCHAR(255) NOT NULL,
                    crop_type_id VARCHAR(36),
                    date_planted DATE,
                    harvest_date DATE,
                    number_of_beds INT DEFAULT 0,
                    plant_spacing VARCHAR(255),
                    bed_spacing VARCHAR(255),
                    bed_length FLOAT DEFAULT 0,
                    is_double_sided BOOLEAN DEFAULT FALSE,
                    left_side_length FLOAT DEFAULT 0,
                    right_side_length FLOAT DEFAULT 0,
                    FOREIGN KEY (field_id) REFERENCES Fields(id) ON DELETE CASCADE,
                    FOREIGN KEY (crop_type_id) REFERENCES CropTypes(id) ON DELETE SET NULL
                )
            `);

            // 5. Beds
            await conn.query(`
                CREATE TABLE IF NOT EXISTS Beds (
                    id VARCHAR(36) PRIMARY KEY,
                    crop_id VARCHAR(36) NOT NULL,
                    name VARCHAR(255) NOT NULL,
                    length FLOAT DEFAULT 0,
                    is_double_sided BOOLEAN DEFAULT FALSE,
                    left_side_length FLOAT DEFAULT 0,
                    right_side_length FLOAT DEFAULT 0,
                    FOREIGN KEY (crop_id) REFERENCES Crops(id) ON DELETE CASCADE
                )
            `);

            // 6. Tasks
            await conn.query(`
                CREATE TABLE IF NOT EXISTS Tasks (
                    id VARCHAR(36) PRIMARY KEY,
                    description TEXT NOT NULL,
                    assigned_to VARCHAR(36),
                    assigned_by VARCHAR(36),
                    due_date DATE NOT NULL,
                    assigned_on DATETIME DEFAULT CURRENT_TIMESTAMP,
                    field_id VARCHAR(36),
                    crop_id VARCHAR(36),
                    status VARCHAR(50) DEFAULT 'pending',
                    FOREIGN KEY (assigned_to) REFERENCES Users(id) ON DELETE SET NULL,
                    FOREIGN KEY (assigned_by) REFERENCES Users(id) ON DELETE SET NULL,
                    FOREIGN KEY (field_id) REFERENCES Fields(id) ON DELETE SET NULL,
                    FOREIGN KEY (crop_id) REFERENCES Crops(id) ON DELETE SET NULL
                )
            `);

            // 7. Inventory Categories
            await conn.query(`
                CREATE TABLE IF NOT EXISTS InventoryCategories (
                    id VARCHAR(36) PRIMARY KEY,
                    name VARCHAR(50) NOT NULL UNIQUE
                )
            `);
            const defaultCats = ['fertilizer', 'insecticide', 'fungicide', 'herbicide', 'pesticide', 'bio', 'tool'];
            for (const cat of defaultCats) {
                const [rows]: any = await conn.query('SELECT id FROM InventoryCategories WHERE name = ?', [cat]);
                if (rows.length === 0) {
                    await conn.query('INSERT INTO InventoryCategories (id, name) VALUES (?, ?)', [uuidv4(), cat]);
                }
            }

            // 8. Inventory
            await conn.query(`
                CREATE TABLE IF NOT EXISTS Inventory (
                    id VARCHAR(36) PRIMARY KEY,
                    name VARCHAR(255) NOT NULL,
                    category_id VARCHAR(36),
                    unit VARCHAR(20) DEFAULT 'kg',
                    quantity FLOAT DEFAULT 0,
                    cost_per_unit FLOAT DEFAULT 0,
                    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                    FOREIGN KEY (category_id) REFERENCES InventoryCategories(id) ON DELETE SET NULL
                )
            `);

            // 9. Task Materials
            await conn.query(`
                CREATE TABLE IF NOT EXISTS task_materials (
                    task_id VARCHAR(36) NOT NULL,
                    inventory_id VARCHAR(36) NOT NULL,
                    quantity_used FLOAT DEFAULT 0,
                    unit VARCHAR(20) DEFAULT 'kg',
                    PRIMARY KEY (task_id, inventory_id),
                    FOREIGN KEY (task_id) REFERENCES Tasks(id) ON DELETE CASCADE,
                    FOREIGN KEY (inventory_id) REFERENCES Inventory(id) ON DELETE CASCADE
                )
            `);

            // 10. Transactions
            await conn.query(`
                CREATE TABLE IF NOT EXISTS Transactions (
                    id VARCHAR(36) PRIMARY KEY,
                    title VARCHAR(255) NOT NULL,
                    amount DOUBLE NOT NULL,
                    date DATE NOT NULL,
                    category VARCHAR(100) NOT NULL,
                    description TEXT,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )
            `);

            await conn.commit();
            res.json({ success: true, message: 'Database setup complete with all tables and seed data.' });

        } catch (error: any) {
            await conn.rollback();
            console.error('DB Setup Failed:', error);
            res.status(500).json({ error: error.message });
        } finally {
            conn.release();
        }
    };

    public setupAdmin = async (req: Request, res: Response) => {
        const { username, password } = req.body;
        if (!username || !password) {
            res.status(400).json({ error: 'Username and password required' });
            return;
        }

        const pool = Database.getInstance().getPool();
        try {
            const [rows]: any = await pool.query('SELECT id FROM Users WHERE username = ?', [username]);
            if (rows.length > 0) {
                res.json({ success: true, message: 'Admin already exists.' });
                return;
            }

            const hashedPassword = await bcrypt.hash(password, 10);
            await pool.query(
                'INSERT INTO Users (id, username, password, role) VALUES (?, ?, ?, ?)',
                [uuidv4(), username, hashedPassword, 'admin']
            );
            res.json({ success: true, message: 'Admin created successfully.' });
        } catch (e: any) {
            res.status(500).json({ error: e.message });
        }
    };

    public debugTables = async (req: Request, res: Response) => {
        const pool = Database.getInstance().getPool();
        try {
            const [rows] = await pool.query('SHOW TABLES');
            res.json(rows);
        } catch (e: any) {
            res.status(500).json({ error: e.message });
        }
    };
}
