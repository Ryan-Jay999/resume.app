import { createEmptyResume, Resume } from './Models';

export class SampleData {
  static createResume(): Resume {
    const resume: Resume = createEmptyResume('cs_intern', '示例 · 计算机实习');
    resume.personal = {
      name: '林晓',
      phone: '138 0000 0000',
      email: 'linxiao@example.com',
      school: '江南大学',
      major: '计算机科学与技术',
      degree: '本科',
      graduation: '2027-06',
      city: '无锡',
      github: 'github.com/linxiao'
    };
    resume.education = [
      {
        id: 'sample_edu_1',
        title: '江南大学',
        role: '计算机科学与技术 · 本科',
        start: '2023-09',
        end: '2027-06',
        detail: 'GPA 3.6/4.0，专业排名前 15%；主修数据结构、操作系统、计算机网络、数据库原理。'
      }
    ];
    resume.project = [
      {
        id: 'sample_project_1',
        title: '校园二手交易应用',
        role: '前端负责人 · ArkTS',
        start: '2025-03',
        end: '2025-06',
        detail: '基于 HarmonyOS 开发校园二手交易应用，负责首页、发布与聊天模块；' +
          '使用 ArkTS 与 relationalStore 完成本地数据持久化；内测累计 300+ 注册用户，日活约 60。'
      }
    ];
    resume.award = [
      {
        id: 'sample_award_1',
        title: '蓝桥杯软件赛',
        role: '省赛二等奖',
        start: '',
        end: '2025-04',
        detail: 'Java 程序设计赛道，省内排名前 15%。'
      }
    ];
    resume.studentWork = [
      {
        id: 'sample_work_1',
        title: '计算机学院学生会',
        role: '宣传部干事',
        start: '2023-10',
        end: '2024-06',
        detail: '负责 5 场院级活动的视觉物料与推文，单篇最高阅读量 2000+。'
      }
    ];
    resume.skills = [
      {
        id: 'sample_skill_1',
        name: '编程语言',
        items: 'Java、Python、ArkTS、JavaScript'
      },
      {
        id: 'sample_skill_2',
        name: '前端与工具',
        items: 'ArkUI、Vue、Git、Linux'
      }
    ];
    resume.certificates = [
      {
        id: 'sample_cert_1',
        title: '大学英语四级',
        role: '512 分',
        start: '',
        end: '2024-12',
        detail: ''
      }
    ];
    resume.summary = '计算机专业本科在读，方向为前端与鸿蒙应用开发，有完整的项目落地经验。' +
      '习惯用数据衡量结果，希望在一线研发团队持续成长。';
    return resume;
  }
}
