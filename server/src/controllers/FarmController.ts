import { Request, Response } from 'express';
import { Database } from '../database/Database';
import { Config } from '../config/Config';
import { v4 as uuidv4 } from 'uuid';

export class FarmController {
    private pool = Database.getInstance().getPool();

    // --- CROP TYPES ---

    public getCropTypes = async (req: Request, res: Response) => {
        try {
            const [rows] = await this.pool.query('SELECT * FROM CropTypes ORDER BY name ASC');
            res.json(rows);
        } catch (e: any) {
            res.status(500).json({ error: e.message });
        }
    };

    public createCropType = async (req: Request, res: Response) => {
        const { name } = req.body;
        if (!name) return res.status(400).json({ error: 'Name is required' });

        try {
            await this.pool.query('INSERT INTO CropTypes (id, name) VALUES (?, ?)', [uuidv4(), name]);
            res.json({ success: true, message: 'Crop type added' });
        } catch (e: any) {
            if (e.code === 'ER_DUP_ENTRY') {
                return res.status(409).json({ error: 'Crop type already exists' });
            }
            res.status(500).json({ error: e.message });
        }
    };

    public deleteCropType = async (req: Request, res: Response) => {
        try {
            await this.pool.query('DELETE FROM CropTypes WHERE id = ?', [req.params.id]);
            res.json({ success: true, message: 'Crop type deleted' });
        } catch (e: any) {
            res.status(500).json({ error: e.message });
        }
    };

    // --- FIELDS ---

    public getFields = async (req: Request, res: Response) => {
        try {
            const [rows] = await this.pool.query('SELECT * FROM Fields ORDER BY created_at DESC');
            res.json(rows);
        } catch (e: any) {
            res.status(500).json({ error: e.message });
        }
    };

    public createField = async (req: Request, res: Response) => {
        const { id, name, location, sizeAcres, kml_file_name, kml_content, crops } = req.body;

        const validSize = (sizeAcres && !isNaN(parseFloat(sizeAcres))) ? parseFloat(sizeAcres) : 0.0;
        if (!name) {
            return res.status(400).json({ error: 'Field name is required' });
        }

        const connection = await this.pool.getConnection();
        try {
            await connection.beginTransaction();

            await connection.query(
                'INSERT INTO Fields (id, name, location, size_acres, kml_file_name, kml_content) VALUES (?, ?, ?, ?, ?, ?)',
                [id || uuidv4(), name, location || '', validSize, kml_file_name || null, kml_content || null]
            );

            // Create nested crops if provided
            if (crops && Array.isArray(crops)) {
                for (const crop of crops) {
                    const bedCount = parseInt(crop.bedCount) || 0;
                    const bedLength = parseInt(crop.bedLength) || 0;
                    const plantSpacing = crop.plantSpacing || '';
                    const bedSpacing = crop.bedSpacing || '';
                    const isDouble = crop.isDoubleSided ? 1 : 0;
                    const left = isDouble ? (parseInt(crop.leftSide) || 0) : 0;
                    const right = isDouble ? (parseInt(crop.rightSide) || 0) : 0;

                    await connection.query(
                        `INSERT INTO Crops 
                        (id, field_id, name, crop_type_id, date_planted, harvest_date, 
                         number_of_beds, plant_spacing, bed_spacing, bed_length, is_double_sided, left_side_length, right_side_length) 
                        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
                        [
                            crop.id || uuidv4(),
                            id,
                            crop.name,
                            crop.crop_type_id || null,
                            crop.datePlanted || null,
                            null,
                            bedCount,
                            plantSpacing,
                            bedSpacing,
                            bedLength,
                            isDouble,
                            left,
                            right
                        ]
                    );
                }
            }

            await connection.commit();
            res.json({ success: true, message: Config.MESSAGES.CREATED });
        } catch (e: any) {
            await connection.rollback();
            console.error('Create Field Error:', e);
            res.status(500).json({ error: e.message });
        } finally {
            connection.release();
        }
    };

    public updateField = async (req: Request, res: Response) => {
        const { name, location, sizeAcres, kml_file_name, kml_content } = req.body;
        try {
            await this.pool.query(
                'UPDATE Fields SET name=?, location=?, size_acres=?, kml_file_name=?, kml_content=? WHERE id=?',
                [name, location, sizeAcres, kml_file_name || null, kml_content || null, req.params.id]
            );
            res.json({ success: true, message: Config.MESSAGES.UPDATED });
        } catch (e: any) {
            res.status(500).json({ error: e.message });
        }
    };

    public deleteField = async (req: Request, res: Response) => {
        const connection = await this.pool.getConnection();
        try {
            const { id } = req.params;
            await connection.beginTransaction();
            await connection.query('SET FOREIGN_KEY_CHECKS=0');

            await connection.query('DELETE FROM Tasks WHERE crop_id IN (SELECT id FROM Crops WHERE field_id = ?)', [id]);
            await connection.query('DELETE FROM Tasks WHERE field_id = ?', [id]);
            await connection.query('DELETE FROM Beds WHERE crop_id IN (SELECT id FROM Crops WHERE field_id = ?)', [id]);
            await connection.query('DELETE FROM Crops WHERE field_id = ?', [id]);
            const [result]: any = await connection.query('DELETE FROM Fields WHERE id = ?', [id]);

            await connection.query('SET FOREIGN_KEY_CHECKS=1');

            if (result.affectedRows === 0) {
                await connection.rollback();
                return res.status(404).json({ error: 'Field not found' });
            }

            await connection.commit();
            res.json({ success: true, message: Config.MESSAGES.DELETED });
        } catch (e: any) {
            await connection.rollback();
            await connection.query('SET FOREIGN_KEY_CHECKS=1');
            res.status(500).json({ error: e.message });
        } finally {
            connection.release();
        }
    };

    // --- CROPS ---

    public getAllCrops = async (req: Request, res: Response) => {
        try {
            const query = `
                SELECT 
                    id, field_id, name, crop_type_id,
                    date_planted as datePlanted, 
                    harvest_date as harvestDate, 
                    number_of_beds as numberOfBeds, 
                    plant_spacing as plantSpacing,
                    bed_spacing as bedSpacing,
                    bed_length as bedLength,
                    is_double_sided as isDoubleSided,
                    left_side_length as leftSideLength,
                    right_side_length as rightSideLength
                FROM Crops
                ORDER BY date_planted DESC
            `;
            const [rows] = await this.pool.query(query);
            res.json(rows);
        } catch (e: any) {
            res.status(500).json({ error: e.message });
        }
    };

    public getCrops = async (req: Request, res: Response) => {
        try {
            const query = `
                SELECT 
                    id, field_id, name, crop_type_id,
                    date_planted as datePlanted, 
                    harvest_date as harvestDate, 
                    number_of_beds as numberOfBeds, 
                    plant_spacing as plantSpacing,
                    bed_spacing as bedSpacing,
                    bed_length as bedLength,
                    is_double_sided as isDoubleSided,
                    left_side_length as leftSideLength,
                    right_side_length as rightSideLength
                FROM Crops 
                WHERE field_id = ? 
                ORDER BY date_planted DESC
            `;
            const [rows] = await this.pool.query(query, [req.params.fieldId]);
            res.json(rows);
        } catch (e: any) {
            res.status(500).json({ error: e.message });
        }
    };

    public createCrop = async (req: Request, res: Response) => {
        const {
            id, fieldId, name, crop_type_id, datePlanted, harvestDate,
            bedCount, plantSpacing, bedSpacing, bedLength,
            isDoubleSided, leftSide, rightSide
        } = req.body;

        try {
            await this.pool.query(
                `INSERT INTO Crops (
                    id, field_id, name, crop_type_id, date_planted, harvest_date, 
                    number_of_beds, plant_spacing, bed_spacing, bed_length, 
                    is_double_sided, left_side_length, right_side_length
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
                [
                    id || uuidv4(),
                    fieldId,
                    name,
                    crop_type_id || null,
                    datePlanted || null,
                    harvestDate || null,
                    bedCount || 0,
                    plantSpacing || '',
                    bedSpacing || '',
                    bedLength || 0,
                    isDoubleSided ? 1 : 0,
                    leftSide || 0,
                    rightSide || 0
                ]
            );
            res.json({ success: true });
        } catch (e: any) {
            res.status(500).json({ error: e.message });
        }
    };

    public updateCrop = async (req: Request, res: Response) => {
        const { id } = req.params;
        const dbPayload = {
            name: req.body.name,
            crop_type_id: req.body.crop_type_id || null,
            date_planted: req.body.datePlanted || null,
            harvest_date: req.body.harvestDate || null,
            number_of_beds: parseInt(req.body.bedCount) || 0,
            plant_spacing: req.body.plantSpacing || '',
            bed_spacing: req.body.bedSpacing || '',
            bed_length: parseInt(req.body.bedLength) || 0,
            is_double_sided: req.body.isDoubleSided ? 1 : 0,
            left_side_length: parseInt(req.body.leftSide) || 0,
            right_side_length: parseInt(req.body.rightSide) || 0
        };

        try {
            await this.pool.query('UPDATE Crops SET ? WHERE id = ?', [dbPayload, id]);
            res.json({ success: true, message: Config.MESSAGES.UPDATED });
        } catch (e: any) {
            res.status(500).json({ error: e.message });
        }
    };

    public deleteCrop = async (req: Request, res: Response) => {
        try {
            const [result]: any = await this.pool.query('DELETE FROM Crops WHERE id = ?', [req.params.id]);
            if (result.affectedRows === 0) return res.status(404).json({ error: 'Crop not found' });
            res.json({ message: Config.MESSAGES.DELETED });
        } catch (e: any) {
            res.status(500).json({ error: e.message });
        }
    };

    // --- BEDS ---

    public getBeds = async (req: Request, res: Response) => {
        try {
            const [rows] = await this.pool.query<any[]>(
                'SELECT * FROM Beds WHERE crop_id = ? ORDER BY name ASC', [req.params.cropId]
            );
            const cleanRows = rows.map(r => ({ ...r, is_double_sided: !!r.is_double_sided }));
            res.json(cleanRows);
        } catch (e: any) {
            res.status(500).json({ error: e.message });
        }
    };

    public createBed = async (req: Request, res: Response) => {
        const { id, cropId, name, length, isDoubleSided, leftSide, rightSide } = req.body;
        try {
            await this.pool.query(
                'INSERT INTO Beds (id, crop_id, name, length, is_double_sided, left_side_length, right_side_length) VALUES (?, ?, ?, ?, ?, ?, ?)',
                [id || uuidv4(), cropId, name, length, isDoubleSided, leftSide, rightSide]
            );
            res.json({ success: true });
        } catch (e: any) {
            res.status(500).json({ error: e.message });
        }
    };

    public updateBed = async (req: Request, res: Response) => {
        const { name, length, isDoubleSided, leftSide, rightSide } = req.body;
        try {
            await this.pool.query(
                'UPDATE Beds SET name=?, length=?, is_double_sided=?, left_side_length=?, right_side_length=? WHERE id=?',
                [name, length, isDoubleSided, leftSide, rightSide, req.params.id]
            );
            res.json({ success: true });
        } catch (e: any) {
            res.status(500).json({ error: e.message });
        }
    };

    public deleteBed = async (req: Request, res: Response) => {
        try {
            await this.pool.query('DELETE FROM Beds WHERE id=?', [req.params.id]);
            res.json({ success: true });
        } catch (e: any) {
            res.status(500).json({ error: e.message });
        }
    };
}
