import {
  Controller, Post, Get, Body, Param, Injectable, Module, NestModule,
  MiddlewareConsumer, RequestMethod, UseGuards, UsePipes, UseInterceptors, CallHandler,
  ExecutionContext, Injectable as InjectableInterceptor, NestInterceptor, PipeTransform, ArgumentMetadata,
  CanActivate, HttpStatus, HttpException, ValidationPipe
} from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Entity, PrimaryGeneratedColumn, Column, ManyToOne, CreateDateColumn, OneToMany, Repository } from 'typeorm';
import { IsNotEmpty } from 'class-validator';
import { InjectRepository } from '@nestjs/typeorm';
import { v4 as uuid } from 'uuid';
import * as morgan from 'morgan';

// ========================== ENTITIES ==========================

@Entity()
export class User {
  @PrimaryGeneratedColumn()
  id: number;

  @Column()
  username: string;

  @OneToMany(() => Conversation, conv => conv.user)
  conversations: Conversation[];
}

@Entity()
export class Conversation {
  @PrimaryGeneratedColumn()
  id: number;

  @Column()
  userText: string;

  @Column()
  correctedText: string;

  @Column()
  fluencyScore: number;

  @CreateDateColumn()
  createdAt: Date;

  @ManyToOne(() => User, user => user.conversations)
  user: User;
}

@Entity()
export class MediaPrompt {
  @PrimaryGeneratedColumn()
  id: number;

  @Column()
  type: 'image' | 'video';

  @Column()
  url: string;

  @Column()
  prompt: string;
}

// ========================== DTOs ==========================

export class CreateUserDTO {
  @IsNotEmpty()
  username: string;
}

export class AddConversationDTO {
  @IsNotEmpty()
  userId: number;

  @IsNotEmpty()
  userText: string;
}

// ========================== GUARD ==========================

@Injectable()
export class ApiKeyGuard implements CanActivate {
  canActivate(context: ExecutionContext): boolean {
    const req = context.switchToHttp().getRequest();
    if (req.headers['x-api-key'] === 'sivi-key') return true;
    throw new HttpException('Unauthorized', HttpStatus.UNAUTHORIZED);
  }
}

// ========================== PIPE ==========================

@Injectable()
export class TrimTextPipe implements PipeTransform {
  transform(value: any, metadata: ArgumentMetadata) {
    if (value.userText) value.userText = value.userText.trim();
    return value;
  }
}

// ========================== INTERCEPTOR ==========================

@InjectableInterceptor()
export class ResponseFormatter implements NestInterceptor {
  intercept(context: ExecutionContext, next: CallHandler) {
    return next.handle().then(data => ({
      success: true,
      data,
      timestamp: new Date().toISOString(),
    }));
  }
}

// ========================== SERVICES ==========================

@Injectable()
export class UserService {
  constructor(@InjectRepository(User) private repo: Repository<User>) {}

  async create(username: string) {
    const user = this.repo.create({ username });
    return this.repo.save(user);
  }

  async find(id: number) {
    return this.repo.findOne({ where: { id }, relations: ['conversations'] });
  }
}

@Injectable()
export class ConversationService {
  constructor(
    @InjectRepository(Conversation) private repo: Repository<Conversation>,
    @InjectRepository(User) private userRepo: Repository<User>,
  ) {}

  correctGrammar(text: string): string {
    return text.replace(/\bi am\b/gi, 'I am')
               .replace(/\bi dont\b/gi, "I don't")
               .replace(/\bi cant\b/gi, "I can't");
  }

  scoreText(text: string): number {
    const penalties = (text.match(/um|uh|like|you know/gi) || []).length;
    return Math.max(0, 100 - penalties * 10);
  }

  async add(userId: number, userText: string) {
    const user = await this.userRepo.findOneBy({ id: userId });
    if (!user) throw new HttpException('User not found', 404);

    const correctedText = this.correctGrammar(userText);
    const score = this.scoreText(userText);

    const conversation = this.repo.create({ user, userText, correctedText, fluencyScore: score });
    return this.repo.save(conversation);
  }

  async getUserConversations(userId: number) {
    return this.repo.find({ where: { user: { id: userId } }, order: { createdAt: 'DESC' } });
  }
}

@Injectable()
export class MediaService {
  constructor(@InjectRepository(MediaPrompt) private repo: Repository<MediaPrompt>) {}

  async randomPrompt() {
    const prompts = await this.repo.find();
    return prompts[Math.floor(Math.random() * prompts.length)];
  }
}

// ========================== CONTROLLERS ==========================

@Controller('users')
export class UserController {
  constructor(private readonly service: UserService) {}

  @Post()
  async create(@Body() dto: CreateUserDTO) {
    return this.service.create(dto.username);
  }

  @Get(':id')
  async get(@Param('id') id: number) {
    return this.service.find(id);
  }
}

@Controller('conversation')
@UseGuards(ApiKeyGuard)
@UsePipes(new TrimTextPipe())
@UseInterceptors(ResponseFormatter)
export class ConversationController {
  constructor(private readonly service: ConversationService) {}

  @Post()
  async add(@Body() dto: AddConversationDTO) {
    return this.service.add(dto.userId, dto.userText);
  }

  @Get(':userId')
  async getHistory(@Param('userId') id: number) {
    return this.service.getUserConversations(id);
  }
}

@Controller('media')
export class MediaController {
  constructor(private readonly service: MediaService) {}

  @Get()
  async getPrompt() {
    return this.service.randomPrompt();
  }
}

// ========================== MIDDLEWARE ==========================

export class LoggerMiddleware {
  use(req, res, next) {
    console.log(`[${new Date().toISOString()}] ${req.method} ${req.url}`);
    next();
  }
}

// ========================== MODULE ==========================

@Module({
  imports: [
    TypeOrmModule.forRoot({
      type: 'sqlite',
      database: 'sivi.db',
      synchronize: true,
      entities: [User, Conversation, MediaPrompt],
    }),
    TypeOrmModule.forFeature([User, Conversation, MediaPrompt]),
  ],
  controllers: [UserController, ConversationController, MediaController],
  providers: [
    UserService,
    ConversationService,
    MediaService,
    ResponseFormatter,
    TrimTextPipe,
    ApiKeyGuard,
  ],
})
export class AppModule implements NestModule {
  configure(consumer: MiddlewareConsumer) {
    consumer
      .apply(LoggerMiddleware, morgan('tiny'))
      .forRoutes({ path: '*', method: RequestMethod.ALL });
  }
}

// ========================== BOOTSTRAP ==========================

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  app.enableCors();
  await app.listen(3000);
  console.log('Sivi backend running at http://localhost:3000');
}
bootstrap();
