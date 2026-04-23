# Lifer 数据库与字段设计文档

## 1. 文档目标

本文档用于定义 Lifer 应用 V1 的本地数据库方案，覆盖：

- 数据库技术路线
- 核心表结构与字段定义
- 枚举与约束设计
- 索引与查询优化建议
- 迁移策略
- 与 JSON 导入导出的映射规则

本文档默认以 `SQLite + Drift` 为实现基础。

## 2. 数据库设计原则

### 2.1 设计原则

- 本地优先，离线可用
- 关系型建模优先，保证统计与筛选能力
- 保留审计与历史记录，不轻易覆盖历史值
- 支持分类嵌套、商品自定义、批次库存、价格分析
- 为未来 AI、同步、家庭共享预留扩展字段

### 2.2 建模原则

- 分类采用邻接表模型：`parent_id`
- 商品分为消耗品与常驻品
- 消耗品库存采用批次建模
- 价格记录与补货记录分离，但支持关联
- 所有统计尽量依赖原始事件表，而不是只存聚合结果
- 提醒规则与提醒命中结果分离

## 3. 数据库技术方案

推荐方案：

- 数据库引擎：SQLite
- ORM / 类型安全层：Drift
- 时间字段：统一存 UTC ISO 时间戳或 epoch millis
- 金额字段：建议用“最小货币单位整数”存储，避免浮点误差

金额建议：

- `amount_minor` 表示最小货币单位
- 例如人民币 `12.34` 元存为 `1234`

数量建议：

- 如果商品单位可能出现小数，数量字段建议用 `REAL`
- 若后续需要更高精度，可转为“整数 + 精度位”方案

## 4. 枚举设计

## 4.1 product_type

- `consumable`：消耗品
- `durable`：常驻品

## 4.2 channel_type

- `online`
- `offline`

## 4.3 reminder_rule_type

- `restock`
- `expiry`
- `manual`
- `price_target`

## 4.4 reminder_threshold_type

- `quantity`
- `ratio`
- `days_before_expiry`
- `fixed_time`
- `price_less_or_equal`

## 4.5 repeat_mode

- `once`
- `daily`
- `interval`

## 4.6 usage_type

- `normal`
- `waste`
- `manual_adjust`
- `recipe`

## 4.7 import_mode

- `merge`
- `replace`

## 5. 核心表结构

以下表结构为 V1 推荐最小闭环方案。

## 5.1 categories

用途：

- 支持用户自建多级分类

字段：

| 字段名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| id | TEXT | 是 | UUID |
| parent_id | TEXT | 否 | 父分类 ID，顶级分类为空 |
| name | TEXT | 是 | 分类名称 |
| sort_order | INTEGER | 是 | 排序值 |
| is_archived | INTEGER | 是 | 0/1 |
| color | TEXT | 否 | 预留分类颜色 |
| icon_uri | TEXT | 否 | 分类图标 |
| created_at | INTEGER | 是 | epoch millis |
| updated_at | INTEGER | 是 | epoch millis |

约束：

- `parent_id` 外键指向 `categories.id`
- 同一父分类下 `name` 唯一

索引：

- `idx_categories_parent_sort(parent_id, sort_order)`
- `idx_categories_name(name)`

## 5.2 units

用途：

- 存储商品计量单位及单位换算基础

字段：

| 字段名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| id | TEXT | 是 | UUID |
| name | TEXT | 是 | 显示名称，如 kg、袋、瓶 |
| symbol | TEXT | 是 | 单位符号 |
| unit_type | TEXT | 是 | mass、volume、count、length 等 |
| base_unit_symbol | TEXT | 否 | 基础单位，如 g、ml、pcs |
| to_base_factor | REAL | 否 | 换算因子 |
| allow_decimal | INTEGER | 是 | 0/1 |
| created_at | INTEGER | 是 | epoch millis |
| updated_at | INTEGER | 是 | epoch millis |

说明：

- V1 可先只支持简单换算
- 对不能换算的离散单位，`to_base_factor` 可为空

## 5.3 products

用途：

- 存储商品主信息

字段：

| 字段名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| id | TEXT | 是 | UUID |
| category_id | TEXT | 是 | 主分类 |
| name | TEXT | 是 | 商品名称 |
| alias | TEXT | 否 | 别名，逗号分隔或后续拆表 |
| product_type | TEXT | 是 | consumable / durable |
| logo_uri | TEXT | 否 | 本地路径或远程 URI |
| unit_id | TEXT | 否 | 默认单位 |
| brand | TEXT | 否 | 品牌 |
| sku_text | TEXT | 否 | 用户自定义规格 |
| expected_price_minor | INTEGER | 否 | 目标价格 |
| currency_code | TEXT | 否 | CNY 等 |
| default_shelf_life_days | INTEGER | 否 | 默认保质期天数 |
| is_pinned_home | INTEGER | 是 | 首页固定商品 |
| home_sort_order | INTEGER | 否 | 首页固定排序 |
| is_archived | INTEGER | 是 | 0/1 |
| notes | TEXT | 否 | 备注 |
| nutrition_tags_json | TEXT | 否 | AI 扩展字段 |
| metadata_json | TEXT | 否 | 扩展字段 |
| created_at | INTEGER | 是 | epoch millis |
| updated_at | INTEGER | 是 | epoch millis |

约束：

- `category_id` 外键指向 `categories.id`
- `unit_id` 外键指向 `units.id`

索引：

- `idx_products_category(category_id)`
- `idx_products_type(product_type)`
- `idx_products_home(is_pinned_home, home_sort_order)`
- `idx_products_name(name)`

## 5.4 product_tags

用途：

- 支持后续按标签筛选，如“食材”“清洁”“宠物”

字段：

| 字段名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| id | TEXT | 是 | UUID |
| name | TEXT | 是 | 标签名 |
| sort_order | INTEGER | 是 | 排序 |
| created_at | INTEGER | 是 | epoch millis |

## 5.5 product_tag_relations

字段：

| 字段名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| product_id | TEXT | 是 | 商品 ID |
| tag_id | TEXT | 是 | 标签 ID |

联合主键：

- `(product_id, tag_id)`

## 5.6 purchase_channels

用途：

- 记录不同购买渠道，支持线上和线下

字段：

| 字段名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| id | TEXT | 是 | UUID |
| name | TEXT | 是 | 渠道名 |
| channel_type | TEXT | 是 | online / offline |
| url | TEXT | 否 | 线上链接 |
| address | TEXT | 否 | 线下地址 |
| latitude | REAL | 否 | 线下经纬度 |
| longitude | REAL | 否 | 线下经纬度 |
| notes | TEXT | 否 | 备注 |
| created_at | INTEGER | 是 | epoch millis |
| updated_at | INTEGER | 是 | epoch millis |

索引：

- `idx_purchase_channels_name(name)`

## 5.7 price_records

用途：

- 记录价格历史，用于价格曲线与支出分析

字段：

| 字段名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| id | TEXT | 是 | UUID |
| product_id | TEXT | 是 | 商品 ID |
| channel_id | TEXT | 否 | 渠道 ID |
| amount_minor | INTEGER | 是 | 总价最小货币单位 |
| currency_code | TEXT | 是 | 币种 |
| quantity | REAL | 否 | 本次购买数量 |
| unit_id | TEXT | 否 | 单位 |
| unit_price_minor | INTEGER | 否 | 单位价格，可冗余存储 |
| purchased_at | INTEGER | 是 | 购买时间 |
| source_type | TEXT | 否 | manual/import/future_crawler |
| notes | TEXT | 否 | 备注 |
| created_at | INTEGER | 是 | epoch millis |
| updated_at | INTEGER | 是 | epoch millis |

约束：

- `product_id` 外键指向 `products.id`
- `channel_id` 外键指向 `purchase_channels.id`
- `unit_id` 外键指向 `units.id`

索引：

- `idx_price_records_product_time(product_id, purchased_at DESC)`
- `idx_price_records_channel(channel_id)`
- `idx_price_records_product_channel_time(product_id, channel_id, purchased_at DESC)`

## 5.8 storage_locations

用途：

- 管理一个或多个存放位置

字段：

| 字段名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| id | TEXT | 是 | UUID |
| parent_id | TEXT | 否 | 支持位置层级，如厨房/冰箱/冷藏层 |
| name | TEXT | 是 | 名称 |
| notes | TEXT | 否 | 备注 |
| sort_order | INTEGER | 是 | 排序 |
| created_at | INTEGER | 是 | epoch millis |
| updated_at | INTEGER | 是 | epoch millis |

索引：

- `idx_storage_locations_parent(parent_id, sort_order)`

## 5.9 stock_batches

用途：

- 记录消耗品库存批次

字段：

| 字段名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| id | TEXT | 是 | UUID |
| product_id | TEXT | 是 | 商品 ID |
| source_price_record_id | TEXT | 否 | 来源价格记录 |
| channel_id | TEXT | 否 | 购买渠道 |
| total_quantity | REAL | 是 | 批次总量 |
| remaining_quantity | REAL | 是 | 批次剩余量 |
| unit_id | TEXT | 是 | 单位 |
| production_date | INTEGER | 否 | 生产日期 |
| purchased_at | INTEGER | 否 | 购买日期 |
| expiry_date | INTEGER | 否 | 到期日期 |
| opened_at | INTEGER | 否 | 开封时间 |
| batch_label | TEXT | 否 | 用户自定义批次名 |
| storage_notes | TEXT | 否 | 批次备注 |
| is_archived | INTEGER | 是 | 0/1 |
| created_at | INTEGER | 是 | epoch millis |
| updated_at | INTEGER | 是 | epoch millis |

关键约束：

- `remaining_quantity >= 0`
- `total_quantity > 0`
- `remaining_quantity <= total_quantity`

索引：

- `idx_stock_batches_product(product_id)`
- `idx_stock_batches_expiry(expiry_date)`
- `idx_stock_batches_product_remaining(product_id, remaining_quantity)`
- `idx_stock_batches_product_expiry(product_id, expiry_date)`

## 5.10 stock_batch_locations

用途：

- 一个批次可分配到多个存放位置

字段：

| 字段名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| id | TEXT | 是 | UUID |
| batch_id | TEXT | 是 | 批次 ID |
| location_id | TEXT | 是 | 位置 ID |
| quantity | REAL | 是 | 该位置存放数量 |
| created_at | INTEGER | 是 | epoch millis |
| updated_at | INTEGER | 是 | epoch millis |

约束：

- `quantity >= 0`

索引：

- `idx_stock_batch_locations_batch(batch_id)`
- `idx_stock_batch_locations_location(location_id)`

## 5.11 restock_records

用途：

- 记录补货事件

字段：

| 字段名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| id | TEXT | 是 | UUID |
| product_id | TEXT | 是 | 商品 ID |
| batch_id | TEXT | 否 | 补货产生的批次 ID |
| price_record_id | TEXT | 否 | 对应价格记录 |
| quantity | REAL | 是 | 补货数量 |
| unit_id | TEXT | 是 | 单位 |
| occurred_at | INTEGER | 是 | 发生时间 |
| notes | TEXT | 否 | 备注 |
| created_at | INTEGER | 是 | epoch millis |

索引：

- `idx_restock_records_product_time(product_id, occurred_at DESC)`

## 5.12 consumption_records

用途：

- 记录消耗品消耗事件

字段：

| 字段名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| id | TEXT | 是 | UUID |
| product_id | TEXT | 是 | 商品 ID |
| batch_id | TEXT | 否 | 消耗批次 ID |
| quantity | REAL | 是 | 消耗数量 |
| unit_id | TEXT | 是 | 单位 |
| occurred_at | INTEGER | 是 | 发生时间 |
| usage_type | TEXT | 是 | normal / waste / manual_adjust / recipe |
| notes | TEXT | 否 | 备注 |
| created_at | INTEGER | 是 | epoch millis |

约束：

- `quantity > 0`

索引：

- `idx_consumption_records_product_time(product_id, occurred_at DESC)`
- `idx_consumption_records_batch(batch_id)`

## 5.13 durable_usage_periods

用途：

- 记录常驻品使用周期与平均日开销

字段：

| 字段名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| id | TEXT | 是 | UUID |
| product_id | TEXT | 是 | 商品 ID |
| price_record_id | TEXT | 否 | 对应购买价格 |
| start_at | INTEGER | 是 | 使用开始 |
| end_at | INTEGER | 否 | 使用结束，未结束为空 |
| purchase_price_minor | INTEGER | 否 | 购买价格 |
| currency_code | TEXT | 否 | 币种 |
| average_daily_cost_minor | INTEGER | 否 | 冗余存储 |
| notes | TEXT | 否 | 备注 |
| created_at | INTEGER | 是 | epoch millis |
| updated_at | INTEGER | 是 | epoch millis |

约束：

- 若 `end_at` 不为空，则 `end_at >= start_at`

索引：

- `idx_durable_usage_periods_product_time(product_id, start_at DESC)`

## 5.14 reminder_rules

用途：

- 存储用户对商品设置的提醒规则

字段：

| 字段名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| id | TEXT | 是 | UUID |
| product_id | TEXT | 是 | 商品 ID |
| rule_type | TEXT | 是 | restock / expiry / manual / price_target |
| threshold_type | TEXT | 是 | quantity / ratio / days_before_expiry / fixed_time / price_less_or_equal |
| threshold_value | REAL | 否 | 阈值 |
| notify_time_text | TEXT | 否 | 如 09:00 |
| lead_time_days | INTEGER | 否 | 提前天数 |
| lead_time_hours | INTEGER | 否 | 提前小时 |
| repeat_mode | TEXT | 是 | once / daily / interval |
| repeat_interval_hours | INTEGER | 否 | interval 模式下使用 |
| is_enabled | INTEGER | 是 | 0/1 |
| priority | INTEGER | 是 | 用户手动优先级 |
| created_at | INTEGER | 是 | epoch millis |
| updated_at | INTEGER | 是 | epoch millis |

索引：

- `idx_reminder_rules_product(product_id)`
- `idx_reminder_rules_enabled(is_enabled, rule_type)`

## 5.15 reminder_events

用途：

- 存储规则计算后的命中记录，便于首页提醒与通知调度

字段：

| 字段名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| id | TEXT | 是 | UUID |
| rule_id | TEXT | 是 | 提醒规则 ID |
| product_id | TEXT | 是 | 商品 ID |
| batch_id | TEXT | 否 | 批次 ID |
| event_type | TEXT | 是 | shortage / expiry / manual / price_target |
| urgency_score | INTEGER | 是 | 紧急度 |
| due_at | INTEGER | 否 | 理论触发时间 |
| notified_at | INTEGER | 否 | 实际通知时间 |
| is_resolved | INTEGER | 是 | 0/1 |
| resolved_at | INTEGER | 否 | 解决时间 |
| snapshot_json | TEXT | 否 | 命中时快照 |
| created_at | INTEGER | 是 | epoch millis |
| updated_at | INTEGER | 是 | epoch millis |

索引：

- `idx_reminder_events_active(is_resolved, urgency_score DESC, due_at ASC)`
- `idx_reminder_events_product(product_id, is_resolved)`

## 5.16 product_note_links

用途：

- 商品与外部笔记、Obsidian 路径、URI 关联

字段：

| 字段名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| id | TEXT | 是 | UUID |
| product_id | TEXT | 是 | 商品 ID |
| title | TEXT | 是 | 显示标题 |
| link_type | TEXT | 是 | obsidian_uri / obsidian_path / web / local_file |
| uri | TEXT | 否 | 外部 URI |
| obsidian_path | TEXT | 否 | Vault 相对路径 |
| notes | TEXT | 否 | 备注 |
| created_at | INTEGER | 是 | epoch millis |
| updated_at | INTEGER | 是 | epoch millis |

索引：

- `idx_product_note_links_product(product_id)`

## 5.17 app_settings

用途：

- 存储应用级设置

字段：

| 字段名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| id | INTEGER | 是 | 固定为 1 |
| language_code | TEXT | 否 | 语言 |
| currency_code | TEXT | 否 | 默认货币 |
| notifications_enabled | INTEGER | 是 | 0/1 |
| theme_mode | TEXT | 否 | system/light/dark |
| obsidian_vault_path | TEXT | 否 | Obsidian 目录 |
| obsidian_uri_scheme | TEXT | 否 | URI Scheme |
| export_encryption_enabled | INTEGER | 是 | 0/1 |
| updated_at | INTEGER | 是 | epoch millis |

## 5.18 import_export_history

用途：

- 记录导入导出历史，便于追踪与排错

字段：

| 字段名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| id | TEXT | 是 | UUID |
| action_type | TEXT | 是 | import / export |
| mode | TEXT | 否 | merge / replace |
| file_path | TEXT | 否 | 文件路径 |
| result | TEXT | 是 | success / failed |
| summary_json | TEXT | 否 | 摘要 |
| created_at | INTEGER | 是 | epoch millis |

## 6. 推荐视图与聚合查询

为提高首页和统计查询效率，建议在 Drift 层维护若干查询或 SQLite View。

## 6.1 v_product_stock_summary

用途：

- 汇总商品总库存、最近到期时间、最近购买时间

核心字段：

- product_id
- total_remaining_quantity
- nearest_expiry_date
- active_batch_count
- last_purchased_at

## 6.2 v_product_last_price

用途：

- 获取商品最近一次购买价格

核心字段：

- product_id
- last_amount_minor
- last_quantity
- last_unit_price_minor
- purchased_at

## 6.3 v_durable_latest_usage

用途：

- 获取常驻品最近使用周期

核心字段：

- product_id
- latest_start_at
- latest_end_at
- latest_average_daily_cost_minor

## 6.4 v_active_reminders

用途：

- 首页提醒商品和提醒列表

核心字段：

- product_id
- max_urgency_score
- nearest_due_at
- active_event_count

## 7. 关键查询场景与索引说明

## 7.1 首页固定商品查询

查询条件：

- `products.is_pinned_home = 1`

排序：

- `home_sort_order ASC`

依赖索引：

- `idx_products_home`

## 7.2 首页提醒商品查询

查询来源：

- `reminder_events`

条件：

- `is_resolved = 0`

排序：

- `urgency_score DESC`
- `due_at ASC`

依赖索引：

- `idx_reminder_events_active`

## 7.3 商品价格曲线

查询条件：

- `product_id`
- `purchased_at BETWEEN ? AND ?`

依赖索引：

- `idx_price_records_product_time`

## 7.4 分类支出统计

连接路径：

- `categories -> products -> price_records`

建议：

- 统计时按 `purchased_at` 范围聚合
- 大量数据时可增加月维度物化统计表，V1 可先不做

## 7.5 消耗趋势统计

连接路径：

- `products -> consumption_records`

依赖索引：

- `idx_consumption_records_product_time`

## 8. 首页紧急度落库策略

推荐两种方案：

### 方案 A：纯实时计算

优点：

- 数据简单

缺点：

- 首页和通知计算逻辑重

### 方案 B：规则 + 事件双表

优点：

- 首页查询快
- 通知调度简单
- 更适合后续复杂提醒

缺点：

- 维护成本略高

结论：

- 推荐 V1 使用方案 B

## 9. 数据一致性规则

### 9.1 消耗品补货

新增补货时需要同时写入：

- `price_records`
- `stock_batches`
- `restock_records`

### 9.2 消耗品消耗

新增消耗时需要同时：

- 写入 `consumption_records`
- 更新对应 `stock_batches.remaining_quantity`
- 重新计算相关提醒事件

### 9.3 常驻品使用周期

开始使用：

- 新增 `durable_usage_periods`

结束使用：

- 更新 `end_at`
- 计算 `average_daily_cost_minor`

### 9.4 分类删除

建议逻辑删除或迁移：

- 不建议直接物理删除存在商品的分类
- 应先迁移商品，再允许删除分类

## 10. JSON 导入导出映射

数据库表与导出字段建议一一对应，降低转换复杂度。

映射建议：

- `categories` -> `categories`
- `units` -> `units`
- `products` -> `products`
- `purchase_channels` -> `purchaseChannels`
- `price_records` -> `priceRecords`
- `stock_batches` -> `stockBatches`
- `storage_locations` -> `storageLocations`
- `stock_batch_locations` -> `stockBatchLocations`
- `restock_records` -> `restockRecords`
- `consumption_records` -> `consumptionRecords`
- `durable_usage_periods` -> `durableUsagePeriods`
- `reminder_rules` -> `reminderRules`
- `reminder_events` -> `reminderEvents`
- `product_note_links` -> `productNoteLinks`
- `app_settings` -> `settings`

建议：

- 导出时 `reminder_events` 可选
- 若导入后会重新计算提醒，则可不强制导出 `reminder_events`

## 11. Drift 实现建议

### 11.1 代码组织建议

推荐目录：

```text
lib/data/local/db/
  app_database.dart
  converters/
  tables/
  daos/
  views/
  migrations/
```

### 11.2 表定义拆分

建议每张表单独文件，例如：

- `categories_table.dart`
- `products_table.dart`
- `price_records_table.dart`

### 11.3 DAO 拆分

建议按业务模块拆分：

- `catalog_dao.dart`
- `pricing_dao.dart`
- `inventory_dao.dart`
- `reminder_dao.dart`
- `settings_dao.dart`

### 11.4 事务建议

以下操作必须在事务内执行：

- 补货
- 消耗
- 导入
- 删除分类并迁移商品
- 常驻品周期结束结算

## 12. 迁移策略

### 12.1 schema version

建议从 `schemaVersion = 1` 开始。

### 12.2 迁移原则

- 只增不改优先
- 对旧字段废弃采用保留兼容策略
- JSON 导入导出版本与 DB schema version 可独立

### 12.3 预期迁移点

后续可能新增：

- 多分类映射表
- 商品成分表
- AI 分析结果表
- 家庭共享同步表
- 冲突解决表

## 13. V1 必需表与可延期表

### 13.1 V1 必需表

- categories
- units
- products
- purchase_channels
- price_records
- storage_locations
- stock_batches
- stock_batch_locations
- restock_records
- consumption_records
- durable_usage_periods
- reminder_rules
- reminder_events
- product_note_links
- app_settings

### 13.2 可延期表

- product_tags
- product_tag_relations
- import_export_history

## 14. 最终建议

V1 数据库设计的关键点不是“字段多”，而是下面四件事必须从一开始就做对：

1. 分类必须支持树形嵌套和排序
2. 消耗品必须按批次建模
3. 价格必须保留历史事件并支持单位价格
4. 提醒必须采用规则与事件分离设计

如果继续推进，下一步建议直接产出：

1. Drift 表定义草稿
2. 首页、价格页、库存页的核心查询 SQL/DAO 设计
3. JSON Schema v1 文档
