# Configuração da Aplicação NestJS para EKS

## 📋 **Ajustes Necessários na Aplicação**

### 1. **Dockerfile Otimizado**

```dockerfile
# Multi-stage build para produção
FROM node:18-alpine AS builder

WORKDIR /app

# Copy package files
COPY package*.json ./
COPY tsconfig*.json ./

# Install dependencies
RUN npm ci --only=development

# Copy source code
COPY src ./src

# Build application
RUN npm run build && npm prune --production

# Production stage
FROM node:18-alpine AS production

WORKDIR /app

# Create non-root user
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nestjs -u 1001

# Copy built application
COPY --from=builder --chown=nestjs:nodejs /app/dist ./dist
COPY --from=builder --chown=nestjs:nodejs /app/node_modules ./node_modules
COPY --from=builder --chown=nestjs:nodejs /app/package*.json ./

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:3000/health || exit 1

USER nestjs

EXPOSE 3000

CMD ["node", "dist/main"]
```

### 2. **Health Check Endpoint**

```typescript
// src/shared/health/health.controller.ts
import { Controller, Get } from '@nestjs/common';
import { 
  HealthCheck, 
  HealthCheckService, 
  TypeOrmHealthIndicator,
  MemoryHealthIndicator 
} from '@nestjs/terminus';

@Controller('health')
export class HealthController {
  constructor(
    private health: HealthCheckService,
    private db: TypeOrmHealthIndicator,
    private memory: MemoryHealthIndicator,
  ) {}

  @Get()
  @HealthCheck()
  check() {
    return this.health.check([
      // Database health
      () => this.db.pingCheck('database'),
      // Memory usage (important for K8s)
      () => this.memory.checkHeap('memory_heap', 150 * 1024 * 1024), // 150MB
      () => this.memory.checkRSS('memory_rss', 300 * 1024 * 1024),   // 300MB
    ]);
  }

  @Get('ready')
  @HealthCheck()
  ready() {
    return this.health.check([
      () => this.db.pingCheck('database'),
    ]);
  }

  @Get('live')
  @HealthCheck() 
  live() {
    return this.health.check([
      () => this.memory.checkHeap('memory_heap', 400 * 1024 * 1024),
    ]);
  }
}
```

### 3. **Configuração de Environment**

```typescript
// src/config/environment.ts
import { plainToClass, Transform } from 'class-transformer';
import { IsString, IsNumber, IsOptional, validateSync } from 'class-validator';

export class EnvironmentVariables {
  @IsString()
  NODE_ENV: string = 'development';

  @IsNumber()
  @Transform(({ value }) => parseInt(value, 10))
  PORT: number = 3000;

  // Database
  @IsString()
  DB_HOST: string;

  @IsNumber()
  @Transform(({ value }) => parseInt(value, 10))
  DB_PORT: number = 5432;

  @IsString()
  DB_USERNAME: string;

  @IsString()
  DB_PASSWORD: string;

  @IsString()
  DB_DATABASE: string;

  // JWT
  @IsString()
  JWT_SECRET: string;

  @IsString()
  @IsOptional()
  JWT_EXPIRES_IN: string = '1h';

  // AWS
  @IsString()
  @IsOptional()
  AWS_REGION: string = 'us-east-1';

  @IsString()
  @IsOptional()
  COGNITO_USER_POOL_ID: string;

  @IsString()
  @IsOptional()
  COGNITO_CLIENT_ID: string;

  // API Gateway
  @IsString()
  @IsOptional()
  API_GATEWAY_URL: string;
}

export function validate(config: Record<string, unknown>) {
  const validatedConfig = plainToClass(
    EnvironmentVariables,
    config,
    { enableImplicitConversion: true },
  );

  const errors = validateSync(validatedConfig, {
    skipMissingProperties: false,
  });

  if (errors.length > 0) {
    throw new Error(errors.toString());
  }
  return validatedConfig;
}
```

### 4. **Graceful Shutdown**

```typescript
// src/main.ts
import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { Logger } from '@nestjs/common';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  const logger = new Logger('Bootstrap');

  // Enable shutdown hooks
  app.enableShutdownHooks();

  // Global prefix
  app.setGlobalPrefix('api/v1');

  // CORS
  app.enableCors({
    origin: process.env.ALLOWED_ORIGINS?.split(',') || true,
    credentials: true,
  });

  const port = process.env.PORT || 3000;
  
  await app.listen(port, '0.0.0.0');
  logger.log(`🚀 Application running on port ${port}`);

  // Graceful shutdown
  process.on('SIGTERM', async () => {
    logger.log('SIGTERM received, shutting down gracefully');
    await app.close();
    process.exit(0);
  });

  process.on('SIGINT', async () => {
    logger.log('SIGINT received, shutting down gracefully');
    await app.close();
    process.exit(0);
  });
}

bootstrap().catch(err => {
  console.error('Error starting application:', err);
  process.exit(1);
});
```

### 5. **Database Connection**

```typescript
// src/config/database.config.ts
import { TypeOrmModuleOptions } from '@nestjs/typeorm';
import { ConfigService } from '@nestjs/config';

export const getDatabaseConfig = (
  configService: ConfigService,
): TypeOrmModuleOptions => ({
  type: 'postgres',
  host: configService.get('DB_HOST'),
  port: configService.get('DB_PORT'),
  username: configService.get('DB_USERNAME'),
  password: configService.get('DB_PASSWORD'),
  database: configService.get('DB_DATABASE'),
  entities: [__dirname + '/../**/*.entity{.ts,.js}'],
  synchronize: configService.get('NODE_ENV') === 'development',
  migrations: [__dirname + '/../migrations/*{.ts,.js}'],
  migrationsRun: true,
  logging: configService.get('NODE_ENV') === 'development',
  // Connection pool for K8s
  extra: {
    max: 10,
    min: 2,
    acquire: 30000,
    idle: 10000,
  },
});
```

## 🔧 **ConfigMap e Secrets no K8s**

### Secrets Encoding:
```bash
# Encode secrets to base64
echo -n "your-db-password" | base64
echo -n "your-jwt-secret" | base64
echo -n "your-cognito-pool-id" | base64
```

### Environment Variables:
- `NODE_ENV=production`
- `PORT=3000`
- `AWS_REGION=us-east-1`
- Database configs via secrets
- JWT configs via secrets

## 📊 **Observabilidade**

### Metrics Endpoint:
```typescript
// src/shared/metrics/metrics.controller.ts
import { Controller, Get } from '@nestjs/common';

@Controller('metrics')
export class MetricsController {
  @Get()
  getMetrics() {
    // Prometheus metrics format
    return `
# HELP http_requests_total Total HTTP requests
# TYPE http_requests_total counter
http_requests_total{method="GET",status="200"} 100
# HELP memory_usage_bytes Memory usage in bytes  
# TYPE memory_usage_bytes gauge
memory_usage_bytes ${process.memoryUsage().heapUsed}
`;
  }
}
```

## 🚀 **Deploy Commands**

```bash
# Apply namespace and configs
kubectl apply -f manifests/application-nestjs/01-namespace.yaml

# Apply deployment
kubectl apply -f manifests/application-nestjs/02-deployment.yaml

# Apply services
kubectl apply -f manifests/application-nestjs/03-service.yaml

# Check deployment
kubectl get pods -n fiap-soat-app
kubectl logs -f deployment/fiap-soat-nestjs -n fiap-soat-app
```
