import { fileIo as fs } from '@kit.CoreFileKit';
import { BackupData, PlanTask, Resume } from '../model/Models';

const RESUME_FILE: string = 'resumes.json';
const TASK_FILE: string = 'tasks.json';
const BACKUP_VERSION: number = 1;

export class LocalStore {
  private static dir: string = '';

  static init(filesDir: string): void {
    LocalStore.dir = filesDir;
    try {
      fs.mkdirSync(filesDir);
    } catch (err) {
      // 目录已存在时忽略
    }
  }

  private static pathOf(name: string): string {
    return LocalStore.dir + '/' + name;
  }

  private static readText(name: string): string {
    if (LocalStore.dir.length === 0) {
      return '';
    }
    const path: string = LocalStore.pathOf(name);
    if (!fs.accessSync(path)) {
      return '';
    }
    try {
      return fs.readTextSync(path);
    } catch (err) {
      return '';
    }
  }

  private static writeText(name: string, text: string): void {
    if (LocalStore.dir.length === 0) {
      return;
    }
    const file = fs.openSync(LocalStore.pathOf(name),
      fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE | fs.OpenMode.TRUNC);
    try {
      fs.writeSync(file.fd, text);
    } finally {
      fs.closeSync(file);
    }
  }

  static loadResumes(): Resume[] {
    const text: string = LocalStore.readText(RESUME_FILE);
    if (text.length === 0) {
      return [];
    }
    try {
      const list: Resume[] = JSON.parse(text) as Resume[];
      list.sort((a: Resume, b: Resume) => b.updatedAt - a.updatedAt);
      return list;
    } catch (err) {
      return [];
    }
  }

  static saveResumes(list: Resume[]): void {
    LocalStore.writeText(RESUME_FILE, JSON.stringify(list));
  }

  static findResume(id: string): Resume | undefined {
    const list: Resume[] = LocalStore.loadResumes();
    for (let i = 0; i < list.length; i++) {
      if (list[i].id === id) {
        return list[i];
      }
    }
    return undefined;
  }

  static upsertResume(resume: Resume): void {
    const list: Resume[] = LocalStore.loadResumes();
    let found: boolean = false;
    for (let i = 0; i < list.length; i++) {
      if (list[i].id === resume.id) {
        list[i] = resume;
        found = true;
        break;
      }
    }
    if (!found) {
      list.push(resume);
    }
    LocalStore.saveResumes(list);
  }

  static deleteResume(id: string): void {
    const list: Resume[] = LocalStore.loadResumes();
    const next: Resume[] = [];
    for (let i = 0; i < list.length; i++) {
      if (list[i].id !== id) {
        next.push(list[i]);
      }
    }
    LocalStore.saveResumes(next);
  }

  static loadTasks(): PlanTask[] {
    const text: string = LocalStore.readText(TASK_FILE);
    if (text.length === 0) {
      return [];
    }
    try {
      return JSON.parse(text) as PlanTask[];
    } catch (err) {
      return [];
    }
  }

  static saveTasks(list: PlanTask[]): void {
    LocalStore.writeText(TASK_FILE, JSON.stringify(list));
  }

  static toBackupText(): string {
    const data: BackupData = {
      version: BACKUP_VERSION,
      exportedAt: Date.now(),
      resumes: LocalStore.loadResumes(),
      tasks: LocalStore.loadTasks()
    };
    return JSON.stringify(data, null, 2);
  }

  static restoreFromText(text: string): boolean {
    try {
      const data: BackupData = JSON.parse(text) as BackupData;
      if (data.resumes === undefined || data.tasks === undefined) {
        return false;
      }
      LocalStore.saveResumes(data.resumes);
      LocalStore.saveTasks(data.tasks);
      return true;
    } catch (err) {
      return false;
    }
  }

  static clearAll(): void {
    LocalStore.saveResumes([]);
    LocalStore.saveTasks([]);
  }
}
