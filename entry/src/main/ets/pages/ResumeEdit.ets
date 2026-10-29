import { promptAction, router } from '@kit.ArkUI';
import {
  createEmptyPersonal,
  createEmptyResume,
  createEntry,
  createSkillGroup,
  EntryItem,
  PersonalInfo,
  Resume,
  sectionPlaceholder,
  SkillGroup,
  TemplateDef
} from '../model/Models';
import { FieldRow } from '../components/FieldRow';
import { ResumePaper } from '../components/ResumePaper';
import { ConfigService } from '../service/ConfigService';
import { DiagnosisService } from '../service/DiagnosisService';
import { LocalStore } from '../service/LocalStore';

interface EditSection {
  key: string;
  name: string;
}

const TEMPLATE_FALLBACK: TemplateDef = {
  id: '',
  name: '',
  category: '',
  scene: 'internet_intern',
  accent: '#2563EB',
  layout: 'classic',
  desc: '',
  order: []
};

const SECTIONS: EditSection[] = [
  { key: 'personal', name: '基本信息' },
  { key: 'education', name: '教育' },
  { key: 'internship', name: '实习' },
  { key: 'project', name: '项目' },
  { key: 'award', name: '奖项' },
  { key: 'studentWork', name: '学工' },
  { key: 'practice', name: '实践' },
  { key: 'skills', name: '技能' },
  { key: 'certificates', name: '证书' },
  { key: 'summary', name: '自评' }
];

@Entry
@Component
struct ResumeEdit {
  @State resume: Resume = createEmptyResume('', '');
  @State personal: PersonalInfo = createEmptyPersonal();
  @State educations: EntryItem[] = [];
  @State internships: EntryItem[] = [];
  @State projects: EntryItem[] = [];
  @State awards: EntryItem[] = [];
  @State studentWorks: EntryItem[] = [];
  @State practices: EntryItem[] = [];
  @State skills: SkillGroup[] = [];
  @State certificates: EntryItem[] = [];
  @State summary: string = '';
  @State title: string = '';
  @State active: string = 'personal';
  @State accent: string = '#2563EB';
  @State template: TemplateDef = TEMPLATE_FALLBACK;
  @State sceneId: string = 'internet_intern';
  @State showPreview: boolean = false;
  @State loaded: boolean = false;

  aboutToAppear(): void {
    const params = router.getParams() as Record<string, string>;
    const id: string = params['id'];
    const found: Resume | undefined = LocalStore.findResume(id);
    if (found === undefined) {
      promptAction.showToast({ message: '简历不存在' });
      return;
    }
    this.resume = found;
    this.personal = found.personal;
    this.educations = found.education;
    this.internships = found.internship;
    this.projects = found.project;
    this.awards = found.award;
    this.studentWorks = found.studentWork;
    this.practices = found.practice;
    this.skills = found.skills;
    this.certificates = found.certificates;
    this.summary = found.summary;
    this.title = found.title;
    const template: TemplateDef | undefined = ConfigService.getTemplate(found.templateId);
    if (template !== undefined) {
      this.accent = template.accent;
      this.template = template;
      this.sceneId = template.scene;
    }
    this.loaded = true;
  }

  aboutToDisappear(): void {
    this.save(false);
  }

  private save(showToast: boolean): void {
    if (!this.loaded) {
      return;
    }
    this.resume.title = this.title;
    this.resume.personal = this.personal;
    this.resume.education = this.educations;
    this.resume.internship = this.internships;
    this.resume.project = this.projects;
    this.resume.award = this.awards;
    this.resume.studentWork = this.studentWorks;
    this.resume.practice = this.practices;
    this.resume.skills = this.skills;
    this.resume.certificates = this.certificates;
    this.resume.summary = this.summary;
    this.resume.updatedAt = Date.now();
    LocalStore.upsertResume(this.resume);
    if (showToast) {
      promptAction.showToast({ message: '已保存' });
    }
  }

  private touch(): void {
    this.resume.updatedAt = Date.now();
  }

  private composite(): Resume {
    const resume: Resume = {
      id: this.resume.id,
      title: this.title,
      templateId: this.resume.templateId,
      updatedAt: this.resume.updatedAt,
      personal: this.personal,
      education: this.educations,
      internship: this.internships,
      project: this.projects,
      award: this.awards,
      studentWork: this.studentWorks,
      practice: this.practices,
      skills: this.skills,
      certificates: this.certificates,
      summary: this.summary
    };
    return resume;
  }

  private score(): number {
    return DiagnosisService.quickScore(this.composite(), this.sceneId);
  }

  private gapCount(): number {
    return DiagnosisService.run(this.composite(), this.sceneId, []).gaps.length;
  }

  private itemsOf(section: string): EntryItem[] {
    switch (section) {
      case 'education':
        return this.educations;
      case 'internship':
        return this.internships;
      case 'project':
        return this.projects;
      case 'award':
        return this.awards;
      case 'studentWork':
        return this.studentWorks;
      case 'practice':
        return this.practices;
      case 'certificates':
        return this.certificates;
      default:
        return [];
    }
  }

  private addItem(section: string): void {
    switch (section) {
      case 'education':
        this.educations = this.educations.concat([createEntry()]);
        break;
      case 'internship':
        this.internships = this.internships.concat([createEntry()]);
        break;
      case 'project':
        this.projects = this.projects.concat([createEntry()]);
        break;
      case 'award':
        this.awards = this.awards.concat([createEntry()]);
        break;
      case 'studentWork':
        this.studentWorks = this.studentWorks.concat([createEntry()]);
        break;
      case 'practice':
        this.practices = this.practices.concat([createEntry()]);
        break;
      case 'certificates':
        this.certificates = this.certificates.concat([createEntry()]);
        break;
      default:
        break;
    }
  }

  private removeItem(section: string, id: string): void {
    switch (section) {
      case 'education':
        this.educations = this.educations.filter((item: EntryItem) => item.id !== id);
        break;
      case 'internship':
        this.internships = this.internships.filter((item: EntryItem) => item.id !== id);
        break;
      case 'project':
        this.projects = this.projects.filter((item: EntryItem) => item.id !== id);
        break;
      case 'award':
        this.awards = this.awards.filter((item: EntryItem) => item.id !== id);
        break;
      case 'studentWork':
        this.studentWorks = this.studentWorks.filter((item: EntryItem) => item.id !== id);
        break;
      case 'practice':
        this.practices = this.practices.filter((item: EntryItem) => item.id !== id);
        break;
      case 'certificates':
        this.certificates = this.certificates.filter((item: EntryItem) => item.id !== id);
        break;
      default:
        break;
    }
  }

  private addSkill(): void {
    this.skills = this.skills.concat([createSkillGroup()]);
  }

  private removeSkill(id: string): void {
    this.skills = this.skills.filter((group: SkillGroup) => group.id !== id);
  }

  private goPreview(): void {
    this.save(false);
    router.pushUrl({ url: 'pages/Preview', params: { id: this.resume.id } });
  }

  private goDiagnosis(): void {
    this.save(false);
    router.pushUrl({ url: 'pages/Diagnosis', params: { id: this.resume.id } });
  }

  @Builder
  entryCard(section: string, item: EntryItem, index: number, titleLabel: string,
    roleLabel: string, showDetail: boolean, showRange: boolean) {
    Column({ space: 4 }) {
      Row() {
        Text(titleLabel + ' ' + (index + 1).toString())
          .fontSize(12)
          .fontColor('#6B7280')
        Blank()
        Text('删除')
          .fontSize(12)
          .fontColor('#EF4444')
          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
          .onClick(() => {
            this.removeItem(section, item.id);
          })
      }
      .width('100%')

      FieldRow({
        label: titleLabel,
        initial: item.title,
        placeholder: '',
        multiline: false,
        onValue: (value: string) => {
          item.title = value;
          this.touch();
        }
      })

      FieldRow({
        label: roleLabel,
        initial: item.role,
        placeholder: '',
        multiline: false,
        onValue: (value: string) => {
          item.role = value;
          this.touch();
        }
      })

      if (showRange) {
        Row({ space: 10 }) {
          FieldRow({
            label: '开始时间',
            initial: item.start,
            placeholder: '2025-03',
            multiline: false,
            onValue: (value: string) => {
              item.start = value;
              this.touch();
            }
          })
            .layoutWeight(1)
          FieldRow({
            label: '结束时间',
            initial: item.end,
            placeholder: '2025-06',
            multiline: false,
            onValue: (value: string) => {
              item.end = value;
              this.touch();
            }
          })
            .layoutWeight(1)
        }
        .width('100%')
      } else {
        FieldRow({
          label: '获得时间',
          initial: item.end,
          placeholder: '2025-06',
          multiline: false,
          onValue: (value: string) => {
            item.end = value;
            this.touch();
          }
        })
      }

      if (showDetail) {
        FieldRow({
          label: '描述',
          initial: item.detail,
          placeholder: sectionPlaceholder(section),
          multiline: true,
          onValue: (value: string) => {
            item.detail = value;
            this.touch();
          }
        })
      }
    }
    .width('100%')
    .padding(14)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .margin({ bottom: 12 })
  }

  @Builder
  sectionEntries(section: string, titleLabel: string, roleLabel: string,
    showDetail: boolean, showRange: boolean) {
    Row() {
      Text('已填写 ' + this.itemsOf(section).length.toString() + ' 项')
        .fontSize(12)
        .fontColor('#6B7280')
      Blank()
      Text('+ 添加')
        .fontSize(12)
        .fontColor(this.accent)
        .onClick(() => {
          this.addItem(section);
        })
    }
    .width('100%')
    .margin({ bottom: 10 })

    ForEach(this.itemsOf(section), (item: EntryItem, index: number) => {
      this.entryCard(section, item, index, titleLabel, roleLabel, showDetail, showRange)
    }, (item: EntryItem) => item.id)

    Text('+ 新增一条')
      .fontSize(13)
      .fontColor('#6B7280')
      .textAlign(TextAlign.Center)
      .width('100%')
      .padding({ top: 10, bottom: 10 })
      .backgroundColor('#FFFFFF')
      .borderRadius(10)
      .border({ width: 1, color: '#E5E7EB', style: BorderStyle.Dashed })
      .onClick(() => {
        this.addItem(section);
      })
  }

  @Builder
  personalForm() {
    Column({ space: 4 }) {
      FieldRow({
        label: '简历名称',
        initial: this.title,
        placeholder: '例如：通用版 / 后端实习版',
        multiline: false,
        onValue: (value: string) => {
          this.title = value;
          this.touch();
        }
      })
      FieldRow({
        label: '姓名',
        initial: this.personal.name,
        placeholder: '张三',
        multiline: false,
        onValue: (value: string) => {
          this.personal.name = value;
          this.touch();
        }
      })
      Row({ space: 10 }) {
        FieldRow({
          label: '手机号',
          initial: this.personal.phone,
          placeholder: '138 0000 0000',
          multiline: false,
          onValue: (value: string) => {
            this.personal.phone = value;
            this.touch();
          }
        })
          .layoutWeight(1)
        FieldRow({
          label: '邮箱',
          initial: this.personal.email,
          placeholder: 'name@example.com',
          multiline: false,
          onValue: (value: string) => {
            this.personal.email = value;
            this.touch();
          }
        })
          .layoutWeight(1)
      }
      .width('100%')
      FieldRow({
        label: '学校',
        initial: this.personal.school,
        placeholder: '江南大学',
        multiline: false,
        onValue: (value: string) => {
          this.personal.school = value;
          this.touch();
        }
      })
      Row({ space: 10 }) {
        FieldRow({
          label: '专业',
          initial: this.personal.major,
          placeholder: '计算机科学与技术',
          multiline: false,
          onValue: (value: string) => {
            this.personal.major = value;
            this.touch();
          }
        })
          .layoutWeight(1)
        FieldRow({
          label: '学历',
          initial: this.personal.degree,
          placeholder: '本科',
          multiline: false,
          onValue: (value: string) => {
            this.personal.degree = value;
            this.touch();
          }
        })
          .layoutWeight(1)
      }
      .width('100%')
      Row({ space: 10 }) {
        FieldRow({
          label: '毕业时间',
          initial: this.personal.graduation,
          placeholder: '2027-06',
          multiline: false,
          onValue: (value: string) => {
            this.personal.graduation = value;
            this.touch();
          }
        })
          .layoutWeight(1)
        FieldRow({
          label: '所在城市',
          initial: this.personal.city,
          placeholder: '无锡',
          multiline: false,
          onValue: (value: string) => {
            this.personal.city = value;
            this.touch();
          }
        })
          .layoutWeight(1)
      }
      .width('100%')
      FieldRow({
        label: 'GitHub / 作品集',
        initial: this.personal.github,
        placeholder: 'github.com/yourname',
        multiline: false,
        onValue: (value: string) => {
          this.personal.github = value;
          this.touch();
        }
      })
    }
    .width('100%')
    .padding(14)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
  }

  @Builder
  skillsForm() {
    Row() {
      Text('已填写 ' + this.skills.length.toString() + ' 组')
        .fontSize(12)
        .fontColor('#6B7280')
      Blank()
      Text('+ 添加')
        .fontSize(12)
        .fontColor(this.accent)
        .onClick(() => {
          this.addSkill();
        })
    }
    .width('100%')
    .margin({ bottom: 10 })

    ForEach(this.skills, (group: SkillGroup, index: number) => {
      Column({ space: 4 }) {
        Row() {
          Text('技能组 ' + (index + 1).toString())
            .fontSize(12)
            .fontColor('#6B7280')
          Blank()
          Text('删除')
            .fontSize(12)
            .fontColor('#EF4444')
            .onClick(() => {
              this.removeSkill(group.id);
            })
        }
        .width('100%')
        FieldRow({
          label: '分类',
          initial: group.name,
          placeholder: '例如：编程语言 / 前端 / 工具',
          multiline: false,
          onValue: (value: string) => {
            group.name = value;
            this.touch();
          }
        })
        FieldRow({
          label: '技能内容',
          initial: group.items,
          placeholder: '例如：Java、Python、ArkTS',
          multiline: true,
          onValue: (value: string) => {
            group.items = value;
            this.touch();
          }
        })
      }
      .width('100%')
      .padding(14)
      .backgroundColor('#FFFFFF')
      .borderRadius(12)
      .margin({ bottom: 12 })
    }, (group: SkillGroup) => group.id)

    Text('+ 新增技能组')
      .fontSize(13)
      .fontColor('#6B7280')
      .textAlign(TextAlign.Center)
      .width('100%')
      .padding({ top: 10, bottom: 10 })
      .backgroundColor('#FFFFFF')
      .borderRadius(10)
      .border({ width: 1, color: '#E5E7EB', style: BorderStyle.Dashed })
      .onClick(() => {
        this.addSkill();
      })
  }

  build() {
    Column() {
      Row() {
        Text('‹')
          .fontSize(28)
          .fontColor('#111827')
          .width(32)
          .onClick(() => {
            router.back();
          })
        Text('编辑简历')
          .fontSize(17)
          .fontWeight(FontWeight.Medium)
          .fontColor('#111827')
        Blank()
        Text(this.showPreview ? '收起预览' : '实时预览')
          .fontSize(12)
          .fontColor(this.accent)
          .padding({ left: 10, right: 10, top: 6, bottom: 6 })
          .backgroundColor('#FFFFFF')
          .borderRadius(14)
          .margin({ right: 8 })
          .onClick(() => {
            this.showPreview = !this.showPreview;
          })
        Text('保存')
          .fontSize(13)
          .fontColor('#FFFFFF')
          .padding({ left: 14, right: 14, top: 6, bottom: 6 })
          .backgroundColor(this.accent)
          .borderRadius(14)
          .onClick(() => {
            this.save(true);
          })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 10 })

      Scroll() {
        Row({ space: 8 }) {
          ForEach(SECTIONS, (section: EditSection) => {
            Text(section.name)
              .fontSize(12)
              .fontColor(this.active === section.key ? '#FFFFFF' : '#4B5563')
              .padding({ left: 12, right: 12, top: 7, bottom: 7 })
              .backgroundColor(this.active === section.key ? this.accent : '#FFFFFF')
              .borderRadius(14)
              .onClick(() => {
                this.active = section.key;
              })
          }, (section: EditSection) => section.key)
        }
        .padding({ left: 16, right: 16, bottom: 4 })
      }
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
      .width('100%')
      .height(42)
      .flexShrink(0)

      Scroll() {
        Column() {
          if (this.active === 'personal') {
            this.personalForm()
          } else if (this.active === 'education') {
            this.sectionEntries('education', '学校', '专业 · 学历', true, true)
          } else if (this.active === 'internship') {
            this.sectionEntries('internship', '公司', '岗位', true, true)
          } else if (this.active === 'project') {
            this.sectionEntries('project', '项目名称', '角色 · 技术栈', true, true)
          } else if (this.active === 'award') {
            this.sectionEntries('award', '奖项名称', '级别 · 名次', true, true)
          } else if (this.active === 'studentWork') {
            this.sectionEntries('studentWork', '组织 / 部门', '职务', true, true)
          } else if (this.active === 'practice') {
            this.sectionEntries('practice', '实践项目', '角色', true, true)
          } else if (this.active === 'certificates') {
            this.sectionEntries('certificates', '证书名称', '成绩 · 等级', false, false)
          } else if (this.active === 'skills') {
            this.skillsForm()
          } else if (this.active === 'summary') {
            Column() {
              FieldRow({
                label: '自我评价',
                initial: this.summary,
                placeholder: sectionPlaceholder('summary'),
                multiline: true,
                onValue: (value: string) => {
                  this.summary = value;
                  this.touch();
                }
              })
            }
            .width('100%')
            .padding(14)
            .backgroundColor('#FFFFFF')
            .borderRadius(12)
          }

          Row({ space: 8 }) {
            Text('自动自检')
              .fontSize(11)
              .fontColor('#6B7280')
            Text('匹配度 ' + this.score().toString())
              .fontSize(12)
              .fontWeight(FontWeight.Medium)
              .fontColor('#111827')
            Text('·')
              .fontSize(11)
              .fontColor('#C4C8CE')
            Text('缺口 ' + this.gapCount().toString() + ' 项')
              .fontSize(12)
              .fontColor('#EF4444')
            Blank()
            Text('查看')
              .fontSize(11)
              .fontColor(this.accent)
          }
          .width('100%')
          .padding({ left: 12, right: 12, top: 10, bottom: 10 })
          .backgroundColor('#FFFFFF')
          .borderRadius(10)
          .margin({ top: 4 })
          .onClick(() => {
            this.goDiagnosis();
          })

          if (this.showPreview) {
            Column({ space: 8 }) {
              Row() {
                Text('实时预览')
                  .fontSize(11)
                  .fontColor('#6B7280')
                Blank()
                Text('随填写内容即时更新')
                  .fontSize(10)
                  .fontColor('#9CA3AF')
              }
              .width('100%')

              ResumePaper({ resume: this.composite(), template: this.template })
            }
            .width('100%')
            .padding(10)
            .backgroundColor('#E9EBEF')
            .borderRadius(12)
            .margin({ top: 10 })
          }

          Text('提示：内容会实时保存在本机，换设备前请到设置页导出备份。')
            .fontSize(11)
            .fontColor('#9CA3AF')
            .width('100%')
            .margin({ top: 8, bottom: 16 })

          Row({ space: 10 }) {
            Text('预览简历')
              .fontSize(14)
              .fontColor(this.accent)
              .textAlign(TextAlign.Center)
              .layoutWeight(1)
              .padding({ top: 11, bottom: 11 })
              .backgroundColor('#FFFFFF')
              .border({ width: 1, color: this.accent })
              .borderRadius(10)
              .onClick(() => {
                this.goPreview();
              })
            Text('一键诊断')
              .fontSize(14)
              .fontColor('#FFFFFF')
              .textAlign(TextAlign.Center)
              .layoutWeight(1)
              .padding({ top: 11, bottom: 11 })
              .backgroundColor(this.accent)
              .borderRadius(10)
              .onClick(() => {
                this.goDiagnosis();
              })
          }
          .width('100%')
          .margin({ bottom: 24 })
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 10 })
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .align(Alignment.Top)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F4F5F7')
  }
}
