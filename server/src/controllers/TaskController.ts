import { Request, Response } from 'express';
import { Database } from '../database/Database';
import { v4 as uuidv4 } from 'uuid';

export class TaskController {
    private pool = Database.getInstance().getPool();

    public getTasks = async (req: Request, res: Response) => {
        try {
            const query = `
                SELECT t.id, t.description, t.status, 
                       t.due_date as dueDate, 
                       t.assigned_on as assignedOn, 
                       t.assigned_to as assignedTo, 
                       t.field_id as fieldId, 
                       t.crop_id as cropId, 
                       f.name as fieldName, 
                       c.name as cropName, 
                       u.username as assignedToUsername
                FROM Tasks t
                LEFT JOIN Fields f ON t.field_id = f.id
                LEFT JOIN Crops c ON t.crop_id = c.id
                LEFT JOIN Users u ON t.assigned_to = u.id
                ORDER BY t.due_date ASC
            `;
            const [rows] = await this.pool.query(query);
            res.json(rows);
        } catch (e: any) {
            res.status(500).json({ error: e.message });
        }
    };

    public createTask = async (req: Request, res: Response) => {
        const { id, description, assignedTo, assignedBy, dueDate, assignedOn, fieldId, cropId, inputs } = req.body;

        if (!description || !assignedTo || !dueDate) {
            return res.status(400).json({ error: 'Missing required fields (description, assignedTo, dueDate)' });
        }

        const taskId = id || uuidv4();
        const connection = await this.pool.getConnection();

        try {
            await connection.beginTransaction();

            // 1. Insert Task
            await connection.query(
                `INSERT INTO Tasks (id, description, assigned_to, assigned_by, due_date, assigned_on, field_id, crop_id, status)
                 VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'pending')`,
                [taskId, description, assignedTo, assignedBy, dueDate, assignedOn || new Date(), fieldId, cropId]
            );

            // 2. Insert Materials
            if (inputs && inputs.length > 0) {
                for (const input of inputs) {
                    if (input.id && input.qty) {
                        await connection.query(
                            `INSERT INTO task_materials (task_id, inventory_id, quantity_used, unit) VALUES (?, ?, ?, ?)`,
                            [taskId, input.id, parseFloat(input.qty), input.unit || 'kg']
                        );
                    }
                }
            }

            await connection.commit();
            res.json({ success: true, message: 'Task assigned successfully', id: taskId });
        } catch (e: any) {
            await connection.rollback();
            console.error('Create Task Error:', e);
            res.status(500).json({ error: e.message });
        } finally {
            connection.release();
        }
    };

    public updateTask = async (req: Request, res: Response) => {
        const { id } = req.params;
        const { description, assignedTo, dueDate, fieldId, cropId, inputs } = req.body;

        const connection = await this.pool.getConnection();
        try {
            await connection.beginTransaction();

            await connection.query(
                `UPDATE Tasks SET description=?, assigned_to=?, due_date=?, field_id=?, crop_id=? WHERE id=?`,
                [description, assignedTo, dueDate, fieldId, cropId, id]
            );

            // Wipe old materials, insert new ones
            await connection.query('DELETE FROM task_materials WHERE task_id=?', [id]);

            if (inputs && inputs.length > 0) {
                for (const input of inputs) {
                    if (input.id && input.qty) {
                        await connection.query(
                            `INSERT INTO task_materials (task_id, inventory_id, quantity_used, unit) VALUES (?, ?, ?, ?)`,
                            [id, input.id, parseFloat(input.qty), input.unit || 'kg']
                        );
                    }
                }
            }

            await connection.commit();
            res.json({ success: true, message: 'Task updated successfully' });
        } catch (e: any) {
            await connection.rollback();
            res.status(500).json({ error: e.message });
        } finally {
            connection.release();
        }
    };

    public updateStatus = async (req: Request, res: Response) => {
        const { id } = req.params;
        const { status } = req.body;

        const validStatuses = ['pending', 'in-progress', 'completed', 'cancelled'];
        if (!validStatuses.includes(status)) {
            return res.status(400).json({ error: 'Invalid status' });
        }

        try {
            await this.pool.query(
                'UPDATE Tasks SET status = ?, assigned_on = ? WHERE id = ?',
                [status, new Date(), id]
            );
            res.json({ success: true });
        } catch (e: any) {
            res.status(500).json({ error: e.message });
        }
    };

    public deleteTask = async (req: Request, res: Response) => {
        try {
            await this.pool.query('DELETE FROM Tasks WHERE id = ?', [req.params.id]);
            res.json({ success: true });
        } catch (e: any) {
            res.status(500).json({ error: e.message });
        }
    };

    public getTaskMaterials = async (req: Request, res: Response) => {
        try {
            const query = `
                SELECT 
                    tm.inventory_id, 
                    tm.quantity_used,
                    tm.unit,
                    i.name as inventory_name, 
                    ic.name as category_name
                FROM task_materials tm
                JOIN Inventory i ON tm.inventory_id = i.id
                LEFT JOIN InventoryCategories ic ON i.category_id = ic.id
                WHERE tm.task_id = ?
            `;
            const [rows] = await this.pool.query(query, [req.params.id]);
            res.json(rows);
        } catch (e: any) {
            res.status(500).json({ error: e.message });
        }
    };
}
