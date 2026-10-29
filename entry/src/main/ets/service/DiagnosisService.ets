import { DiagItem, DiagReport, EntryItem, PlanTask, Resume, RuleDef } from '../model/Models';
import { ConfigService } from './ConfigService';
import { PlanService } from './PlanService';

export class DiagnosisService {
  static entriesOf(resume: Resume, section: string): EntryItem[] {
    switch (section) {
      case 'education':
        return resume.education;
      case 'internship':
        return resume.internship;
      case 'project':
        return resume.project;
      case 'award':
        return resume.award;
      case 'studentWork':
        return resume.studentWork;
      case 'practice':
        return resume.practice;
      case 'certificates':
        return resume.certificates;
      default:
        return [];
    }
  }

  static textOf(resume: Resume, section: string): string {
    if (section === 'summary') {
      return resume.summary;
    }
    if (section === 'skills') {
      let text: string = '';
      for (let i = 0; i < resume.skills.length; i++) {
        text += resume.skills[i].name + ' ' + resume.skills[i].items + ' ';
      }
      return text;
    }
    if (section === 'personal') {
      const p = resume.personal;
      return p.name + ' ' + p.phone + ' ' + p.email + ' ' + p.school + ' ' +
        p.major + ' ' + p.degree + ' ' + p.graduation + ' ' + p.city + ' ' + p.github;
    }
    const list: EntryItem[] = DiagnosisService.entriesOf(resume, section);
    let text: string = '';
    for (let i = 0; i < list.length; i++) {
      text += list[i].title + ' ' + list[i].role + ' ' + list[i].start + ' ' +
        list[i].end + ' ' + list[i].detail + ' ';
    }
    return text;
  }

  private static fieldValue(resume: Resume, field: string): string {
    const p = resume.personal;
    switch (field) {
      case 'name':
        return p.name;
      case 'phone':
        return p.phone;
      case 'email':
        return p.email;
      case 'school':
        return p.school;
      case 'major':
        return p.major;
      default:
        return '';
    }
  }

  private static evaluate(rule: RuleDef, resume: Resume): DiagItem {
    let passed: boolean = false;
    let actual: string = '';
    if (rule.type === 'minCount') {
      const list: EntryItem[] = DiagnosisService.entriesOf(resume, rule.section);
      let count: number = 0;
      for (let i = 0; i < list.length; i++) {
        if (list[i].title.trim().length > 0 || list[i].detail.trim().length > 0) {
          count++;
        }
      }
      passed = count >= rule.target;
      actual = '当前 ' + count.toString() + ' 项，建议至少 ' + rule.target.toString() + ' 项';
    } else if (rule.type === 'minDetailChars') {
      const list: EntryItem[] = DiagnosisService.entriesOf(resume, rule.section);
      let chars: number = 0;
      for (let i = 0; i < list.length; i++) {
        chars += list[i].detail.trim().length;
      }
      passed = chars >= rule.target;
      actual = '当前描述共 ' + chars.toString() + ' 字，建议不少于 ' + rule.target.toString() + ' 字';
    } else if (rule.type === 'keywordAny') {
      const lower: string = DiagnosisService.textOf(resume, rule.section).toLowerCase();
      let hit: string = '';
      for (let i = 0; i < rule.keywords.length; i++) {
        if (lower.indexOf(rule.keywords[i].toLowerCase()) >= 0) {
          hit = rule.keywords[i];
          break;
        }
      }
      passed = hit.length > 0;
      actual = passed ? '已命中关键词：' + hit : '未检测到相关关键词';
    } else if (rule.type === 'minChars') {
      const len: number = DiagnosisService.textOf(resume, rule.section).trim().length;
      passed = len >= rule.target;
      actual = '当前 ' + len.toString() + ' 字，建议不少于 ' + rule.target.toString() + ' 字';
    } else if (rule.type === 'fieldNonEmpty') {
      const value: string = DiagnosisService.fieldValue(resume, rule.field);
      passed = value.trim().length > 0;
      actual = passed ? '已填写' : '未填写';
    }

    return {
      ruleId: rule.id,
      title: rule.title,
      passTitle: rule.passTitle,
      advice: rule.advice,
      action: rule.action,
      level: rule.level,
      weight: rule.weight,
      passed: passed,
      actual: actual
    };
  }

  static run(resume: Resume, sceneId: string, tasks: PlanTask[]): DiagReport {
    const scene = ConfigService.getScene(sceneId);
    const sceneName: string = scene === undefined ? '综合评估' : scene.name;
    const items: DiagItem[] = [];
    let lost: number = 0;
    let passedCount: number = 0;
    if (scene !== undefined) {
      for (let i = 0; i < scene.rules.length; i++) {
        const item: DiagItem = DiagnosisService.evaluate(scene.rules[i], resume);
        items.push(item);
        if (item.passed) {
          passedCount++;
        } else {
          lost += item.weight;
        }
      }
    }
    const baseScore: number = Math.max(0, 100 - lost);
    const bonus: number = PlanService.completionBonus(tasks);
    const score: number = Math.min(100, baseScore + bonus);
    const gaps: DiagItem[] = [];
    for (let i = 0; i < items.length; i++) {
      if (!items[i].passed) {
        gaps.push(items[i]);
      }
    }
    gaps.sort((a: DiagItem, b: DiagItem): number => {
      if (a.level !== b.level) {
        return a.level === 'short' ? -1 : 1;
      }
      return b.weight - a.weight;
    });

    return {
      sceneId: sceneId,
      sceneName: sceneName,
      score: score,
      baseScore: baseScore,
      bonus: bonus,
      passedCount: passedCount,
      gapCount: gaps.length,
      items: items,
      gaps: gaps
    };
  }

  static quickScore(resume: Resume, sceneId: string): number {
    const report: DiagReport = DiagnosisService.run(resume, sceneId, []);
    return report.baseScore;
  }
}
