import { addDays, GapInfo, newId, PlanTask } from '../model/Models';

const BONUS_PER_TASK: number = 2;
const BONUS_CAP: number = 10;

export class PlanService {
  static completionBonus(tasks: PlanTask[]): number {
    let done: number = 0;
    for (let i = 0; i < tasks.length; i++) {
      if (tasks[i].done) {
        done++;
      }
    }
    const bonus: number = done * BONUS_PER_TASK;
    return bonus > BONUS_CAP ? BONUS_CAP : bonus;
  }

  static dueOffset(level: string): number {
    return level === 'short' ? 90 : 180;
  }

  static priorityOf(level: string): string {
    return level === 'short' ? 'high' : 'medium';
  }

  static generateTasks(gaps: GapInfo[], existing: PlanTask[]): PlanTask[] {
    const created: PlanTask[] = [];
    for (let i = 0; i < gaps.length; i++) {
      const gap: GapInfo = gaps[i];
      let exists: boolean = false;
      for (let j = 0; j < existing.length; j++) {
        if (existing[j].ruleId === gap.ruleId) {
          exists = true;
          break;
        }
      }
      if (exists) {
        continue;
      }
      created.push({
        id: newId('task'),
        title: gap.action,
        detail: gap.advice,
        due: addDays(PlanService.dueOffset(gap.level)),
        priority: PlanService.priorityOf(gap.level),
        done: false,
        ruleId: gap.ruleId,
        createdAt: Date.now()
      });
    }
    return created;
  }
}
