export class Config {
    static DB = {
        HOST: process.env.DB_HOST || 'localhost',
        USER: process.env.DB_USER || 'root',
        PASS: process.env.DB_PASS || '',
        NAME: process.env.DB_NAME || 'krishi_pradhan',
        LIMIT: parseInt(process.env.DB_LIMIT || '10'),
    };

    static JWT_SECRET = process.env.JWT_SECRET || 'krishi_pradhan_secret';
    static PORT = process.env.PORT || 3000;

    static MESSAGES = {
        DB_CONNECTED: '✅ MySQL Connected',
        DB_ERROR: '❌ MySQL Connection Error:',
        CREATED: 'Created successfully',
        UPDATED: 'Updated successfully',
        DELETED: 'Deleted successfully',
        NOT_FOUND: 'Not found',
        AUTH_FAIL: 'Invalid credentials',
        USER_EXISTS: 'Username already exists',
        USER_NOT_FOUND: 'User not found',
    };
}
