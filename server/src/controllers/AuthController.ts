import { Request, Response } from 'express';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { Database } from '../database/Database';
import { Config } from '../config/Config';
import { RowDataPacket } from 'mysql2';

interface UserRow extends RowDataPacket {
    id: string;
    username: string;
    password?: string;
    role: string;
}

export class AuthController {
    private pool = Database.getInstance().getPool();

    public register = async (req: Request, res: Response): Promise<void> => {
        const { id, username, password, role } = req.body;

        if (!username || !password) {
            res.status(400).json({ error: 'Username and password are required' });
            return;
        }

        try {
            const hashedPassword = await bcrypt.hash(password, 10);
            const validRoles = ['admin', 'worker'];
            const safeRole = validRoles.includes(role) ? role : 'worker';

            await this.pool.query(
                'INSERT INTO Users (id, username, password, role) VALUES (?, ?, ?, ?)',
                [id, username, hashedPassword, safeRole]
            );
            res.json({ success: true, message: Config.MESSAGES.CREATED });
        } catch (e: any) {
            if (e.code === 'ER_DUP_ENTRY') {
                res.status(400).json({ error: Config.MESSAGES.USER_EXISTS });
                return;
            }
            res.status(500).json({ error: e.message });
        }
    };

    public login = async (req: Request, res: Response): Promise<void> => {
        const { username, password } = req.body;
        console.log(`[AUTH] Login attempt: ${username}`);

        try {
            const [users] = await this.pool.query<UserRow[]>(
                'SELECT * FROM Users WHERE username = ?', [username]
            );

            if (users.length === 0) {
                res.status(401).json({ error: Config.MESSAGES.USER_NOT_FOUND });
                return;
            }

            const user = users[0];
            const isMatch = await bcrypt.compare(password, user.password as string);

            if (!isMatch) {
                res.status(401).json({ error: Config.MESSAGES.AUTH_FAIL });
                return;
            }

            const token = jwt.sign(
                { id: user.id, username: user.username, role: user.role },
                Config.JWT_SECRET
            );

            res.json({
                token,
                user: { id: user.id, username: user.username, role: user.role }
            });
        } catch (e: any) {
            res.status(500).json({ error: e.message });
        }
    };

    public getUsers = async (req: Request, res: Response) => {
        try {
            const [users] = await this.pool.query(
                'SELECT id, username, role FROM Users ORDER BY username ASC'
            );
            res.json(users);
        } catch (e: any) {
            res.status(500).json({ error: e.message });
        }
    };

    public changeUserRole = async (req: Request, res: Response) => {
        const { role } = req.body;
        const { id } = req.params;

        const validRoles = ['admin', 'worker'];
        if (!validRoles.includes(role)) {
            res.status(400).json({ error: 'Invalid role' });
            return;
        }

        try {
            await this.pool.query('UPDATE Users SET role = ? WHERE id = ?', [role, id]);
            res.json({ success: true, message: `Role updated to ${role}` });
        } catch (e: any) {
            res.status(500).json({ error: e.message });
        }
    };
}
