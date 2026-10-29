import { promptAction, router } from '@kit.ArkUI';
import {
  createEmptyResume,
  DiagItem,
  DiagReport,
  levelLabel,
  PlanTask,
  Resume,
  SceneDef,
  TemplateDef
} from '../model/Models';
import { ConfigService } from '../service/ConfigService';
import { DiagnosisService } from '../service/DiagnosisService';
import { LocalStore } from '../service/LocalStore';
import { PlanService } from '../service/PlanService';

const EMPTY_REPORT: DiagReport = {
  sceneId: '',
  sceneName: '',
  score: 0,
  baseScore: 0,
  bonus: 0,
  passedCount: 0,
  gapCount: 0,
  items: [],
  gaps: []
};

@Entry
@Component
struct Diagnosis {
  @State resume: Resume = createEmptyResume('', '');
  @State tasks: PlanTask[] = [];
  @State report: DiagReport = EMPTY_REPORT;
  @State sceneId: string = 'internet_intern';
  @State loaded: boolean = false;
  private scenes: SceneDef[] = ConfigService.getScenes();

  aboutToAppear(): void {
    const params = router.getParams() as Record<string, string>;
    const found: Resume | undefined = LocalStore.findResume(params['id']);
    if (found === undefined) {
      promptAction.showToast({ message: '简历不存在' });
      return;
    }
    this.resume = found;
    const template: TemplateDef | undefined = ConfigService.getTemplate(found.templateId);
    if (template !== undefined) {
      this.sceneId = template.scene;
    }
    this.loaded = true;
    this.recalc();
  }

  onPageShow(): void {
    if (this.loaded) {
      this.recalc();
    }
  }

  private recalc(): void {
    this.tasks = LocalStore.loadTasks();
    this.report = DiagnosisService.run(this.resume, this.sceneId, this.tasks);
  }

  private scoreColor(score: number): string {
    if (score >= 80) {
      return '#16A34A';
    }
    if (score >= 60) {
      return '#F59E0B';
    }
    return '#EF4444';
  }

  private generatePlan(): void {
    const existing: PlanTask[] = LocalStore.loadTasks();
    const created: PlanTask[] = PlanService.generateTasks(this.report.gaps, existing);
    if (created.length === 0) {
      promptAction.showToast({ message: '缺口任务已全部加入计划' });
    } else {
      LocalStore.saveTasks(existing.concat(created));
      promptAction.showToast({ message: '已生成 ' + created.length.toString() + ' 项任务' });
    }
    this.recalc();
    router.pushUrl({ url: 'pages/Plan' });
  }

  @Builder
  gapCard(item: DiagItem) {
    Column({ space: 8 }) {
      Row({ space: 8 }) {
        Text(item.level === 'short' ? '短期' : '中长期')
          .fontSize(10)
          .fontColor(item.level === 'short' ? '#B91C1C' : '#B45309')
          .padding({ left: 7, right: 7, top: 2, bottom: 2 })
          .backgroundColor(item.level === 'short' ? '#FEE2E2' : '#FEF3C7')
          .borderRadius(6)
        Text(item.title)
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor('#111827')
          .layoutWeight(1)
        Text('-' + item.weight.toString())
          .fontSize(12)
          .fontColor('#EF4444')
      }
      .width('100%')
      .alignItems(VerticalAlign.Top)

      Text(item.actual)
        .fontSize(11)
        .fontColor('#6B7280')
        .width('100%')

      Text(item.advice)
        .fontSize(12)
        .fontColor('#374151')
        .lineHeight(19)
        .width('100%')

      Row({ space: 6 }) {
        Text('建议动作')
          .fontSize(10)
          .fontColor('#6B7280')
        Text(item.action)
          .fontSize(11)
          .fontColor('#1D4ED8')
          .layoutWeight(1)
      }
      .width('100%')
      .padding({ top: 6 })
      .border({ width: { top: 1 }, color: '#F3F4F6' })
    }
    .width('100%')
    .padding(14)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .margin({ bottom: 10 })
  }

  @Builder
  passedRow(item: DiagItem) {
    Row({ space: 8 }) {
      Text('✓')
        .fontSize(13)
        .fontColor('#16A34A')
      Text(item.passTitle)
        .fontSize(12)
        .fontColor('#374151')
        .layoutWeight(1)
      Text(item.actual)
        .fontSize(10)
        .fontColor('#9CA3AF')
    }
    .width('100%')
    .padding({ top: 7, bottom: 7 })
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
        Text('简历诊断')
          .fontSize(17)
          .fontWeight(FontWeight.Medium)
          .fontColor('#111827')
        Blank()
        Text('成长计划')
          .fontSize(12)
          .fontColor('#374151')
          .padding({ left: 10, right: 10, top: 6, bottom: 6 })
          .backgroundColor('#FFFFFF')
          .borderRadius(14)
          .onClick(() => {
            router.pushUrl({ url: 'pages/Plan' });
          })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 10 })

      Scroll() {
        Column({ space: 12 }) {
          Scroll() {
            Row({ space: 8 }) {
              ForEach(this.scenes, (scene: SceneDef) => {
                Text(scene.name)
                  .fontSize(12)
                  .fontColor(this.sceneId === scene.id ? '#FFFFFF' : '#4B5563')
                  .padding({ left: 12, right: 12, top: 7, bottom: 7 })
                  .backgroundColor(this.sceneId === scene.id ? '#111827' : '#FFFFFF')
                  .borderRadius(14)
                  .onClick(() => {
                    this.sceneId = scene.id;
                    this.recalc();
                  })
              }, (scene: SceneDef) => scene.id)
            }
          }
          .scrollable(ScrollDirection.Horizontal)
          .scrollBar(BarState.Off)
          .width('100%')
          .height(38)

          Row() {
            Stack() {
              Progress({ value: this.report.score, total: 100, type: ProgressType.Ring })
                .width(124)
                .height(124)
                .color(this.scoreColor(this.report.score))
                .style({ strokeWidth: 10 })
              Column({ space: 2 }) {
                Text(this.report.score.toString())
                  .fontSize(34)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(this.scoreColor(this.report.score))
                Text('匹配度')
                  .fontSize(10)
                  .fontColor('#9CA3AF')
              }
            }

            Column({ space: 10 }) {
              Row() {
                Text('目标方向')
                  .fontSize(11)
                  .fontColor('#9CA3AF')
                Blank()
              }
              .width('100%')
              Text(this.report.sceneName)
                .fontSize(14)
                .fontWeight(FontWeight.Medium)
                .fontColor('#111827')
                .width('100%')
              Row() {
                Text('基础分 ' + this.report.baseScore.toString())
                  .fontSize(11)
                  .fontColor('#6B7280')
                Blank()
                Text('规划加分 +' + this.report.bonus.toString())
                  .fontSize(11)
                  .fontColor('#16A34A')
              }
              .width('100%')
              Row() {
                Text('已具备 ' + this.report.passedCount.toString() + ' 项')
                  .fontSize(11)
                  .fontColor('#16A34A')
                Blank()
                Text('缺口 ' + this.report.gapCount.toString() + ' 项')
                  .fontSize(11)
                  .fontColor('#EF4444')
              }
              .width('100%')
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Start)
            .padding({ left: 20 })
          }
          .width('100%')
          .padding(16)
          .backgroundColor('#FFFFFF')
          .borderRadius(14)

          Row() {
            Text('缺失项')
              .fontSize(15)
              .fontWeight(FontWeight.Medium)
              .fontColor('#111827')
            Blank()
            Text('按紧急程度排序')
              .fontSize(10)
              .fontColor('#9CA3AF')
          }
          .width('100%')
          .margin({ top: 4 })

          if (this.report.gaps.length === 0) {
            Text('当前方向没有发现明显缺口，可以继续打磨描述细节。')
              .fontSize(12)
              .fontColor('#16A34A')
              .width('100%')
              .padding(14)
              .backgroundColor('#F0FDF4')
              .borderRadius(12)
          } else {
            ForEach(this.report.gaps, (item: DiagItem) => {
              this.gapCard(item)
            }, (item: DiagItem) => item.ruleId)
          }

          Text('已具备')
            .fontSize(15)
            .fontWeight(FontWeight.Medium)
            .fontColor('#111827')
            .width('100%')
            .margin({ top: 4 })

          Column() {
            ForEach(this.report.items.filter((item: DiagItem) => item.passed), (item: DiagItem) => {
              this.passedRow(item)
            }, (item: DiagItem) => item.ruleId)
          }
          .width('100%')
          .padding({ left: 14, right: 14, top: 4, bottom: 4 })
          .backgroundColor('#FFFFFF')
          .borderRadius(12)

          Text('完成成长计划中的任务，诊断分最多可提升 10 分。')
            .fontSize(11)
            .fontColor('#9CA3AF')
            .width('100%')

          Text('生成成长计划')
            .fontSize(14)
            .fontColor('#FFFFFF')
            .textAlign(TextAlign.Center)
            .width('100%')
            .padding({ top: 12, bottom: 12 })
            .backgroundColor('#2563EB')
            .borderRadius(10)
            .margin({ top: 4, bottom: 24 })
            .onClick(() => {
              this.generatePlan();
            })
        }
        .width('100%')
        .padding({ left: 16, right: 16 })
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
