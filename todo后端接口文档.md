
# Todo 接口文档

这是一个基于 Django REST Framework 的简单待办事项接口，当前项目的统一前置 URL 为：

```text
http://127.0.0.1:8000/o/app
```

因此本应用的完整接口地址都以这个前缀开头。

## 一、数据模型

### TodoItem

| 字段 | 类型 | 说明 | 是否只读 |
| --- | --- | --- | --- |
| `id` | integer | 主键 | 是 |
| `title` | string | 待办标题 | 否 |
| `completed` | boolean | 是否完成 | 否 |
| `created_at` | datetime | 创建时间 | 是 |
| `updated_at` | datetime | 更新时间 | 是 |

## 二、接口列表

### 1. 获取待办列表

- 方法：`GET`
- 地址：`http://127.0.0.1:8000/o/app/api/todos/`

#### 请求示例

```bash
curl http://127.0.0.1:8000/o/app/api/todos/
```

#### 返回示例

```json
[
	{
		"id": 1,
		"title": "学习 Django",
		"completed": false,
		"created_at": "2026-04-18T10:00:00+08:00",
		"updated_at": "2026-04-18T10:00:00+08:00"
	}
]
```

### 2. 新增待办

- 方法：`POST`
- 地址：`http://127.0.0.1:8000/o/app/api/todos/`

#### 请求参数

| 参数 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| `title` | string | 是 | 待办标题 |
| `completed` | boolean | 否 | 是否完成，默认 `false` |

#### 请求示例

```bash
curl -X POST http://127.0.0.1:8000/o/app/api/todos/ \
	-H "Content-Type: application/json" \
	-d '{"title":"写接口文档","completed":false}'
```

#### 返回示例

```json
{
	"id": 2,
	"title": "写接口文档",
	"completed": false,
	"created_at": "2026-04-18T10:10:00+08:00",
	"updated_at": "2026-04-18T10:10:00+08:00"
}
```

### 3. 获取单条待办

- 方法：`GET`
- 地址：`http://127.0.0.1:8000/o/app/api/todos/<id>/`

#### 请求示例

```bash
curl http://127.0.0.1:8000/o/app/api/todos/2/
```

### 4. 更新待办

- 方法：`PUT` / `PATCH`
- 地址：`http://127.0.0.1:8000/o/app/api/todos/<id>/`

#### 请求示例

```bash
curl -X PATCH http://127.0.0.1:8000/o/app/api/todos/2/ \
	-H "Content-Type: application/json" \
	-d '{"completed":true}'
```

### 5. 删除待办

- 方法：`DELETE`
- 地址：`http://127.0.0.1:8000/o/app/api/todos/<id>/`

#### 请求示例

```bash
curl -X DELETE http://127.0.0.1:8000/o/app/api/todos/2/
```

## 三、字段说明

- `title`：待办标题，最多 255 字符
- `completed`：是否完成，`true` 表示已完成，`false` 表示未完成
- `created_at`：创建时间，由系统自动生成
- `updated_at`：更新时间，由系统自动生成

## 四、注意事项

- 当前 `todo` 接口默认没有额外权限控制，直接访问即可
- 接口返回格式由 Django REST Framework 自动生成
- 路由前缀已统一挂载到 `/o/app`，不要遗漏前缀

