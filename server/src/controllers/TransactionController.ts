import { Request, Response } from 'express';
import { Database } from '../database/Database';
import { v4 as uuidv4 } from 'uuid';

export class TransactionController {
    private pool = Database.getInstance().getPool();

    public getTransactions = async (req: Request, res: Response) => {
        try {
            const { start_date, end_date, category } = req.query;
            let query = 'SELECT * FROM Transactions WHERE 1=1';
            const params: any[] = [];

            if (start_date) {
                query += ' AND date >= ?';
                params.push(start_date);
            }
            if (end_date) {
                query += ' AND date <= ?';
                params.push(end_date);
            }
            if (category) {
                query += ' AND category = ?';
                params.push(category);
            }

            query += ' ORDER BY date DESC';
            const [rows] = await this.pool.query(query, params);
            res.json(rows);
        } catch (e: any) {
            res.status(500).json({ error: e.message });
        }
    };

    public getSummary = async (req: Request, res: Response) => {
        try {
            const { month } = req.query; // Format: YYYY-MM
            let dateFilter = '';
            const params: any[] = [];

            if (month) {
                dateFilter = 'WHERE DATE_FORMAT(date, "%Y-%m") = ?';
                params.push(month);
            }

            const [spending]: any = await this.pool.query(
                `SELECT COALESCE(SUM(CASE WHEN amount < 0 THEN ABS(amount) ELSE 0 END), 0) as total_expenses,
                        COALESCE(SUM(CASE WHEN amount > 0 THEN amount ELSE 0 END), 0) as total_income
                 FROM Transactions ${dateFilter}`, params
            );

            const [recent]: any = await this.pool.query(
                `SELECT * FROM Transactions ${dateFilter} ORDER BY date DESC LIMIT 10`, params
            );

            const totalExpenses = spending[0].total_expenses;
            const totalIncome = spending[0].total_income;

            res.json({
                monthlySpending: totalExpenses,
                totalPaid: totalIncome,
                totalDue: totalExpenses - totalIncome,
                paymentPercentage: totalExpenses > 0 ? (totalIncome / totalExpenses) * 100 : 0,
                recentTransactions: recent
            });
        } catch (e: any) {
            res.status(500).json({ error: e.message });
        }
    };

    public createTransaction = async (req: Request, res: Response) => {
        const { title, amount, date, category, description } = req.body;

        if (!title || amount === undefined || !date || !category) {
            return res.status(400).json({ error: 'Missing required fields' });
        }

        try {
            const id = uuidv4();
            await this.pool.query(
                'INSERT INTO Transactions (id, title, amount, date, category, description) VALUES (?, ?, ?, ?, ?, ?)',
                [id, title, amount, date, category, description || null]
            );
            res.json({ success: true, id });
        } catch (e: any) {
            res.status(500).json({ error: e.message });
        }
    };

    public deleteTransaction = async (req: Request, res: Response) => {
        try {
            await this.pool.query('DELETE FROM Transactions WHERE id = ?', [req.params.id]);
            res.json({ success: true });
        } catch (e: any) {
            res.status(500).json({ error: e.message });
        }
    };
}
