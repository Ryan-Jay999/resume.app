import {
  createEmptyResume,
  EntryItem,
  Resume,
  sectionTitle,
  SkillGroup,
  TemplateDef
} from '../model/Models';

const EMPTY_RESUME: Resume = createEmptyResume('', '');
const EMPTY_TEMPLATE: TemplateDef = {
  id: '',
  name: '',
  category: '',
  scene: '',
  accent: '#2563EB',
  layout: 'classic',
  desc: '',
  order: []
};

@Component
export struct ResumePaper {
  @Prop resume: Resume = EMPTY_RESUME;
  @Prop template: TemplateDef = EMPTY_TEMPLATE;

  private entriesOf(key: string): EntryItem[] {
    switch (key) {
      case 'education':
        return this.resume.education;
      case 'internship':
        return this.resume.internship;
      case 'project':
        return this.resume.project;
      case 'award':
        return this.resume.award;
      case 'studentWork':
        return this.resume.studentWork;
      case 'practice':
        return this.resume.practice;
      case 'certificates':
        return this.resume.certificates;
      default:
        return [];
    }
  }

  private hasContent(key: string): boolean {
    if (key === 'summary') {
      return this.resume.summary.trim().length > 0;
    }
    if (key === 'skills') {
      for (let i = 0; i < this.resume.skills.length; i++) {
        const group: SkillGroup = this.resume.skills[i];
        if (group.name.trim().length > 0 || group.items.trim().length > 0) {
          return true;
        }
      }
      return false;
    }
    const list: EntryItem[] = this.entriesOf(key);
    for (let i = 0; i < list.length; i++) {
      if (list[i].title.trim().length > 0 || list[i].detail.trim().length > 0) {
        return true;
      }
    }
    return false;
  }

  private joinParts(parts: string[]): string {
    let text: string = '';
    for (let i = 0; i < parts.length; i++) {
      if (parts[i].trim().length > 0) {
        if (text.length > 0) {
          text += '  ·  ';
        }
        text += parts[i].trim();
      }
    }
    return text;
  }

  private contactLine(): string {
    const p = this.resume.personal;
    return this.joinParts([p.phone, p.email, p.city, p.github]);
  }

  private schoolLine(): string {
    const p = this.resume.personal;
    return this.joinParts([p.school, p.major, p.degree, p.graduation.length > 0 ? p.graduation + ' 毕业' : '']);
  }

  private dateRange(item: EntryItem): string {
    if (item.start.length > 0 && item.end.length > 0) {
      return item.start + ' - ' + item.end;
    }
    if (item.start.length > 0) {
      return item.start;
    }
    return item.end;
  }

  private detailLines(text: string): string[] {
    return text.split('\n').filter((line: string) => line.trim().length > 0);
  }

  @Builder
  sectionBody(key: string) {
    if (this.hasContent(key)) {
      Column() {
        Row({ space: 6 }) {
          Row()
            .width(3)
            .height(13)
            .backgroundColor(this.template.accent)
            .borderRadius(2)
          Text(sectionTitle(key))
            .fontSize(13)
            .fontWeight(FontWeight.Bold)
            .fontColor('#111827')
        }
        .width('100%')
        .margin({ top: 16, bottom: 8 })

        if (key === 'skills') {
          ForEach(this.resume.skills, (group: SkillGroup) => {
            Row() {
              Text(group.name)
                .width(68)
                .fontSize(11)
                .fontColor('#6B7280')
              Text(group.items)
                .layoutWeight(1)
                .fontSize(11)
                .fontColor('#1F2937')
                .lineHeight(18)
            }
            .width('100%')
            .alignItems(VerticalAlign.Top)
            .margin({ bottom: 4 })
          }, (group: SkillGroup) => group.id)
        } else if (key === 'summary') {
          Text(this.resume.summary)
            .fontSize(11.5)
            .fontColor('#1F2937')
            .lineHeight(19)
            .width('100%')
        } else {
          ForEach(this.entriesOf(key), (item: EntryItem) => {
            Column() {
              Row() {
                Text(item.title.length > 0 ? item.title : '未填写')
                  .fontSize(12.5)
                  .fontWeight(FontWeight.Medium)
                  .fontColor('#111827')
                  .layoutWeight(1)
                Text(this.dateRange(item))
                  .fontSize(10)
                  .fontColor('#6B7280')
              }
              .width('100%')

              if (item.role.length > 0) {
                Text(item.role)
                  .fontSize(11)
                  .fontColor('#4B5563')
                  .margin({ top: 2 })
                  .width('100%')
              }
              if (item.detail.trim().length > 0) {
                Column({ space: 2 }) {
                  ForEach(this.detailLines(item.detail), (line: string, index: number) => {
                    Text('· ' + line)
                      .fontSize(11)
                      .fontColor('#374151')
                      .lineHeight(18)
                      .width('100%')
                  }, (line: string, index: number) => item.id + '_' + index.toString())
                }
                .width('100%')
                .margin({ top: 4 })
              }
            }
            .width('100%')
            .alignItems(HorizontalAlign.Start)
            .margin({ bottom: 10 })
          }, (item: EntryItem) => item.id)
        }
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
    }
  }

  build() {
    Column() {
      Column() {
        Row() {
          Column({ space: 5 }) {
            Text(this.resume.personal.name.length > 0 ? this.resume.personal.name : '你的姓名')
              .fontSize(24)
              .fontWeight(FontWeight.Bold)
              .fontColor('#111827')
            Text(this.contactLine())
              .fontSize(10.5)
              .fontColor('#4B5563')
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)

          Text(this.resume.title)
            .fontSize(10)
            .fontColor(this.template.accent)
            .border({ width: 1, color: this.template.accent })
            .borderRadius(10)
            .padding({ left: 8, right: 8, top: 3, bottom: 3 })
        }
        .width('100%')
        .alignItems(VerticalAlign.Top)

        if (this.schoolLine().length > 0) {
          Text(this.schoolLine())
            .fontSize(10.5)
            .fontColor('#4B5563')
            .margin({ top: 6 })
            .width('100%')
        }

        Divider()
          .color(this.template.accent)
          .strokeWidth(2)
          .margin({ top: 12 })
      }
      .width('100%')

      ForEach(this.template.order, (key: string) => {
        this.sectionBody(key)
      }, (key: string) => key)
    }
    .width('100%')
    .padding({ left: 20, right: 20, top: 22, bottom: 26 })
    .backgroundColor('#FFFFFF')
    .alignItems(HorizontalAlign.Start)
  }
}
