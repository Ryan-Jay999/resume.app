export interface PersonalInfo {
  name: string;
  phone: string;
  email: string;
  school: string;
  major: string;
  degree: string;
  graduation: string;
  city: string;
  github: string;
}

export interface EntryItem {
  id: string;
  title: string;
  role: string;
  start: string;
  end: string;
  detail: string;
}

export interface SkillGroup {
  id: string;
  name: string;
  items: string;
}

export interface Resume {
  id: string;
  title: string;
  templateId: string;
  updatedAt: number;
  personal: PersonalInfo;
  education: EntryItem[];
  internship: EntryItem[];
  project: EntryItem[];
  award: EntryItem[];
  studentWork: EntryItem[];
  practice: EntryItem[];
  skills: SkillGroup[];
  certificates: EntryItem[];
  summary: string;
}

export interface PlanTask {
  id: string;
  title: string;
  detail: string;
  due: string;
  priority: string;
  done: boolean;
  ruleId: string;
  createdAt: number;
}

export interface TemplateDef {
  id: string;
  name: string;
  category: string;
  scene: string;
  accent: string;
  layout: string;
  desc: string;
  order: string[];
}

export interface RuleDef {
  id: string;
  section: string;
  type: string;
  target: number;
  keywords: string[];
  field: string;
  weight: number;
  level: string;
  title: string;
  passTitle: string;
  advice: string;
  action: string;
}

export interface SceneDef {
  id: string;
  name: string;
  desc: string;
  rules: RuleDef[];
}

export interface RuleConfig {
  scenes: SceneDef[];
}

export interface GapInfo {
  ruleId: string;
  title: string;
  advice: string;
  action: string;
  level: string;
  weight: number;
}

export interface DiagItem extends GapInfo {
  passTitle: string;
  passed: boolean;
  actual: string;
}

export interface DiagReport {
  sceneId: string;
  sceneName: string;
  score: number;
  baseScore: number;
  bonus: number;
  passedCount: number;
  gapCount: number;
  items: DiagItem[];
  gaps: DiagItem[];
}

export interface BackupData {
  version: number;
  exportedAt: number;
  resumes: Resume[];
  tasks: PlanTask[];
}

export function newId(prefix: string): string {
  const rand: number = Math.floor(Math.random() * 1000000);
  return prefix + '_' + Date.now().toString(36) + '_' + rand.toString(36);
}

export function createEmptyPersonal(): PersonalInfo {
  return {
    name: '',
    phone: '',
    email: '',
    school: '',
    major: '',
    degree: '',
    graduation: '',
    city: '',
    github: ''
  };
}

export function createEntry(): EntryItem {
  return {
    id: newId('item'),
    title: '',
    role: '',
    start: '',
    end: '',
    detail: ''
  };
}

export function createSkillGroup(): SkillGroup {
  return {
    id: newId('skill'),
    name: '',
    items: ''
  };
}

export function createEmptyResume(templateId: string, title: string): Resume {
  return {
    id: newId('resume'),
    title: title,
    templateId: templateId,
    updatedAt: Date.now(),
    personal: createEmptyPersonal(),
    education: [],
    internship: [],
    project: [],
    award: [],
    studentWork: [],
    practice: [],
    skills: [],
    certificates: [],
    summary: ''
  };
}

export function sectionTitle(key: string): string {
  switch (key) {
    case 'education':
      return '教育背景';
    case 'internship':
      return '实习经历';
    case 'project':
      return '项目经历';
    case 'award':
      return '竞赛奖项';
    case 'studentWork':
      return '学生工作';
    case 'practice':
      return '社会实践';
    case 'skills':
      return '专业技能';
    case 'certificates':
      return '证书';
    case 'summary':
      return '自我评价';
    default:
      return '';
  }
}

export function sectionPlaceholder(key: string): string {
  switch (key) {
    case 'education':
      return '例如：GPA 3.7/4.0，专业排名前 10%，主修课程与成绩';
    case 'internship':
      return '描述你负责的工作、使用的方法或工具、产生的可量化结果';
    case 'project':
      return '项目背景 + 你的职责 + 方案与方法 + 结果（尽量写数字）';
    case 'award':
      return '奖项级别、参赛人数、你的排名';
    case 'studentWork':
      return '组织规模、你负责的事项、取得的效果';
    case 'practice':
      return '实践内容、服务对象、时长与成果';
    case 'summary':
      return '用 3 句话说明求职方向、核心优势、代表成果';
    default:
      return '';
  }
}

export function formatDate(date: Date): string {
  const y: number = date.getFullYear();
  const m: number = date.getMonth() + 1;
  const d: number = date.getDate();
  const mm: string = m < 10 ? '0' + m.toString() : m.toString();
  const dd: string = d < 10 ? '0' + d.toString() : d.toString();
  return y.toString() + '-' + mm + '-' + dd;
}

export function addDays(days: number): string {
  const d: Date = new Date();
  d.setDate(d.getDate() + days);
  return formatDate(d);
}

export function formatTime(timestamp: number): string {
  return formatDate(new Date(timestamp));
}

export function levelLabel(level: string): string {
  if (level === 'short') {
    return '短期 · 3 个月内';
  }
  return '中长期 · 半年准备';
}
