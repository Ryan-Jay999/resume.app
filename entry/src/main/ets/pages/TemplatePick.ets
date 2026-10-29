import { router } from '@kit.ArkUI';
import { createEmptyResume, Resume, SceneDef, sectionTitle, TemplateDef } from '../model/Models';
import { ConfigService } from '../service/ConfigService';
import { LocalStore } from '../service/LocalStore';

@Entry
@Component
struct TemplatePick {
  private templates: TemplateDef[] = ConfigService.getTemplates();

  private sceneName(id: string): string {
    const scene: SceneDef | undefined = ConfigService.getScene(id);
    return scene === undefined ? '' : scene.name;
  }

  private useTemplate(template: TemplateDef): void {
    const resume: Resume = createEmptyResume(template.id, template.name + '简历');
    LocalStore.upsertResume(resume);
    router.replaceUrl({ url: 'pages/ResumeEdit', params: { id: resume.id } });
  }

  private categories(): string[] {
    const list: string[] = [];
    for (let i = 0; i < this.templates.length; i++) {
      if (list.indexOf(this.templates[i].category) < 0) {
        list.push(this.templates[i].category);
      }
    }
    return list;
  }

  private templatesOf(category: string): TemplateDef[] {
    const list: TemplateDef[] = [];
    for (let i = 0; i < this.templates.length; i++) {
      if (this.templates[i].category === category) {
        list.push(this.templates[i]);
      }
    }
    return list;
  }

  @Builder
  templateCard(template: TemplateDef) {
    Column({ space: 10 }) {
      Row({ space: 8 }) {
        Row()
          .width(4)
          .height(18)
          .backgroundColor(template.accent)
          .borderRadius(2)
        Text(template.name)
          .fontSize(17)
          .fontWeight(FontWeight.Medium)
          .fontColor('#111827')
        Blank()
        Text(this.sceneName(template.scene))
          .fontSize(10)
          .fontColor(template.accent)
          .padding({ left: 8, right: 8, top: 3, bottom: 3 })
          .border({ width: 1, color: template.accent })
          .borderRadius(10)
      }
      .width('100%')

      Text(template.desc)
        .fontSize(12)
        .fontColor('#6B7280')
        .width('100%')

      Row({ space: 6 }) {
        ForEach(template.order.slice(0, 4), (key: string) => {
          Text(sectionTitle(key))
            .fontSize(10)
            .fontColor('#6B7280')
            .padding({ left: 7, right: 7, top: 3, bottom: 3 })
            .backgroundColor('#F3F4F6')
            .borderRadius(6)
        }, (key: string) => template.id + key)
        Text('等 ' + template.order.length.toString() + ' 项')
          .fontSize(10)
          .fontColor('#9CA3AF')
      }
      .width('100%')

      Text('使用此模板')
        .fontSize(13)
        .fontColor('#FFFFFF')
        .textAlign(TextAlign.Center)
        .width('100%')
        .padding({ top: 9, bottom: 9 })
        .backgroundColor(template.accent)
        .borderRadius(10)
        .onClick(() => {
          this.useTemplate(template);
        })
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(14)
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
        Text('选择模板')
          .fontSize(17)
          .fontWeight(FontWeight.Medium)
          .fontColor('#111827')
        Blank()
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })

      Scroll() {
        Column({ space: 12 }) {
          Text('共 ' + this.templates.length.toString() + ' 套模板，按专业方向分组。模板只决定展示顺序与重点模块，内容随时可以修改。')
            .fontSize(12)
            .fontColor('#6B7280')
            .width('100%')

          ForEach(this.categories(), (category: string) => {
            Column({ space: 10 }) {
              Row({ space: 6 }) {
                Text(category)
                  .fontSize(13)
                  .fontWeight(FontWeight.Medium)
                  .fontColor('#374151')
                Text(this.templatesOf(category).length.toString() + ' 套')
                  .fontSize(10)
                  .fontColor('#9CA3AF')
                Blank()
              }
              .width('100%')
              .padding({ top: 4 })

              ForEach(this.templatesOf(category), (template: TemplateDef) => {
                this.templateCard(template)
              }, (template: TemplateDef) => template.id)
            }
            .width('100%')
            .alignItems(HorizontalAlign.Start)
          }, (category: string) => category)
        }
        .width('100%')
        .padding({ left: 16, right: 16, bottom: 24 })
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
