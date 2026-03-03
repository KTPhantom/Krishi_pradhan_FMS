import express, { Application } from 'express';
import cors from 'cors';
import { AuthController } from './controllers/AuthController';
import { FarmController } from './controllers/FarmController';
import { TaskController } from './controllers/TaskController';
import { TransactionController } from './controllers/TransactionController';
import { SystemController } from './controllers/SystemController';

export class App {
    public app: Application;

    private authController: AuthController;
    private farmController: FarmController;
    private taskController: TaskController;
    private transactionController: TransactionController;
    private systemController: SystemController;

    constructor() {
        this.app = express();
        this.config();

        this.authController = new AuthController();
        this.farmController = new FarmController();
        this.taskController = new TaskController();
        this.transactionController = new TransactionController();
        this.systemController = new SystemController();

        this.routes();
    }

    private config(): void {
        this.app.use(cors());
        this.app.use(express.json({ limit: '10mb' }));
    }

    private routes(): void {
        // Request logger
        this.app.use((req, res, next) => {
            console.log(`🔍 ${req.method} ${req.path}`);
            next();
        });

        // Health check
        this.app.get('/', (req, res) => {
            res.json({ status: '✅ Krishi Pradhan API Running', version: '1.0.0' });
        });

        // --- Auth ---
        this.app.post('/auth/register', this.authController.register);
        this.app.post('/auth/login', this.authController.login);
        this.app.get('/users', this.authController.getUsers);
        this.app.put('/users/:id/role', this.authController.changeUserRole);

        // --- Fields ---
        this.app.get('/fields', this.farmController.getFields);
        this.app.post('/fields', this.farmController.createField);
        this.app.put('/fields/:id', this.farmController.updateField);
        this.app.delete('/fields/:id', this.farmController.deleteField);

        // --- Crop Types ---
        this.app.get('/crop-types', this.farmController.getCropTypes);
        this.app.post('/crop-types', this.farmController.createCropType);
        this.app.delete('/crop-types/:id', this.farmController.deleteCropType);

        // --- Crops ---
        this.app.get('/crops', this.farmController.getAllCrops);
        this.app.get('/fields/:fieldId/crops', this.farmController.getCrops);
        this.app.post('/crops', this.farmController.createCrop);
        this.app.put('/crops/:id', this.farmController.updateCrop);
        this.app.delete('/crops/:id', this.farmController.deleteCrop);

        // --- Beds ---
        this.app.get('/crops/:cropId/beds', this.farmController.getBeds);
        this.app.post('/beds', this.farmController.createBed);
        this.app.put('/beds/:id', this.farmController.updateBed);
        this.app.delete('/beds/:id', this.farmController.deleteBed);

        // --- Tasks ---
        this.app.get('/tasks', this.taskController.getTasks);
        this.app.post('/tasks', this.taskController.createTask);
        this.app.put('/tasks/:id', this.taskController.updateTask);
        this.app.put('/tasks/:id/status', this.taskController.updateStatus);
        this.app.delete('/tasks/:id', this.taskController.deleteTask);
        this.app.get('/tasks/:id/materials', this.taskController.getTaskMaterials);

        // --- Transactions ---
        this.app.get('/transactions', this.transactionController.getTransactions);
        this.app.get('/transactions/summary', this.transactionController.getSummary);
        this.app.post('/transactions', this.transactionController.createTransaction);
        this.app.delete('/transactions/:id', this.transactionController.deleteTransaction);

        // --- System ---
        this.app.get('/setup-database', this.systemController.setupDatabase);
        this.app.post('/setup-admin', this.systemController.setupAdmin);
        this.app.get('/debug/tables', this.systemController.debugTables);
    }
}
