# IM Websocket Protocol

## 关键字解释

mtype —— 消息类型，可能是"text", "gif", "image", "file", "video", "audio" ,"multi","operation"

rtype —— 群聊类型，可能是"group", "private_chat", "self"

左侧：即前端页面中的group_list

右侧：即前端页面中的message_list

成员页：显示群聊成员的页

用户页：显示用户信息的页

## Serialize

### MESSAGE

```json
{
    "message_id": int,
    "sender_id": int,
    "receiver_id": int,
    "index": int, 
    "msg_op":int,
    "content": str,
    "read": bool,
    "recalled": bool,
    "time": str, 
    "mtype": str, 
    "room_id":int,
    "at_ids": list[int]
}
```

### ROOM

```json
{
    "room_id": int,
    "room_name": str,
    "create_time": str,
    "rtype": str,
    "image": str,
    "room_length": int, 
    "owner_id": int,
    "admin_ids": list,
    "members": list[USER],
    "top": bool,
    "no_disturb": bool,
    "unread_cnt": int,
    "latest_message": MESSAGE
}
```

备注：后面四个字段是因人而异的。后端会根据查询者自动计算。

### USER

```json
{
    "user_id": int,
    "user_name": str,
    "email": str,
    "image": str,
    "self_room_id": int
}
```

## 连接websocket

```javascript
// 前端js
FullWSUrl = 'ws://'
            + window.location.host // 本地 若部署则相应更换
            + ws_url // 后端会通过http相应发"ws_url"字段
const chatSocket = new WebSocket(FullWSUrl, [], {
    headers: {
        'Authorization': jwtToken // 后端签发
    }
});
```

## WS API列表

```python
CREATE_ROOM = 0 # 创建群
CREATE_MESSAGE = 1 # 创建消息
INVITE_ROOM_MEMBER = 2 # 群主或群管理员邀请新的群成员
EXIT_ROOM = 3 # 退出群
KICK_ROOM_MEMBER = 4 # 踢出群聊
CHANGE_ROOM_NAME = 5 # 修改群名
CHANGE_ROOM_IMAGE = 6 # 修改群头像
DELETE_ROOM = 7 # 解散群
DELETE_MESSAGE = 8 # 删除消息
RECALL_MESSAGE = 9 # 撤回消息
SET_ADMIN = 10 # 设置管理员
REMOVE_ADMIN = 11 # 取消管理员
TRASFER_OWNER = 12 # 转让群主
CHANGE_ANNOUCEMENT = 13 # 修改群公告
SEND_FRIEND_REQUEST = 14 # 发送好友请求
PROCESS_FRIEND_REQUEST = 15 # 处理好友请求
DELETE_FRIEND = 16 # 删除好友
LOAD_ROOMS = 17 # 加载所有群聊信息
LOAD_HISTORY_MESSAGES = 18 # 加载某一个群聊的所有历史消息
READ_ALL_MESSAGES = 19 # 阅读了某一个群聊的所有消息
LOAD_CONTACTS = 20 # 加载所有联系人信息
DO_NOT_DISTURB = 21 # 设置消息免打扰
ALLOW_DISTURB = 22 # 撤销消息免打扰
SET_AS_TOP = 23 # 置顶聊天
REMOVE_FROM_TOP = 24 # 取消置顶聊天
REVIEW_MEMBERSHIP_REQUESTS = 25 # 审核入群请求
CANCEL_ACCOUNT = 26 # 用户注销
GET_USER_INFO = 27 # 查看用户信息
SEND_INVITE_ROOM_MEMBER_REQUEST = 28 # 普通群成员邀请新的群成员 
```

### 0 - 创建群(已完成)

#### 发请求时机

1. 用户点击了"rtype"为 "private_chat"的群聊成员页的 "+" 按钮
2. 用户点击了创建群聊的 "+" 按钮

#### 请求

```json
{
    "op": 0,
    "data": {
    	"rtype": "group",
        "owner_id":1,
    	"receivers_list":[1, 2, 3, 4]
    }
}
```

#### 响应

私聊

```json
{
    "op": 0,
    "data": {
    	"rtype": "private_chat",
         "owner_id":1,
    	"receivers_list":[1, 2],
	    "room_id":1,
	    "room_name":"",
         "room_image":"",
         "related_message":
        	{
                "mtype":"operation",
                "msg_op":0,
                "room_id":1,
                "sender_id":1,
                "receiver_id":2, 
                "message_id":100,
                "index":20,
                "content":"你们已经成为好友，开始聊天吧！",
                "time":"",
                "recalled":false,
                "read":true
        	}
    }
}
```

群聊

```json
{
    "op": 0,
    "data": {
    	"rtype": "group",
         "owner_id":1,
    	"receivers_list":[1, 2, 3, 4],
	    "room_id":1,
	    "room_name":"",
         "room_image":"",
         "related_message":
        {
        	"mtype":"operation",
            "msg_op":0,
        	"room_id":1,
        	"sender_id":1,
            "receiver_id":2, 
        	"content":"... 创建了群聊，群聊成员有：...",
        	"index":20,
        	"message_id":100,
        	"time":"",
             "recalled":false,
             "read":true
        }
    }
}
```

自己的聊天

```json
{
    "op": 0,
    "data": {
    	"rtype": "group",
         "owner_id":1,
    	"receivers_list":[1],
	    "room_id":1,
	    "room_name":"",
         "room_image":"",
         "related_message":
            {
                "mtype":"operation",
                "msg_op":0,
                "room_id":1,
                "sender_id":1,
                "receiver_id":1,
                "content":"您在这里可以收到其他用户的好友请求，也可以发消息给自己",
                "index":20,
                "message_id":100,
                "time":"",
                 "recalled":false,
                 "read":true
            }
    }
}
```

#### 异常响应

1. 如果 `response["data"]["room_id"]` 为 -1, 则说明因为有些用户不存在而创建失败
2. 如果 `response["data"]["error"]`字段存在且非空，则有各种其他异常

### 1 - 创建消息（已完成）

#### 发请求时机

​	   用户在输入框发送消息

#### 请求

```json
{
    "op":1,
    "data": {
        "mtype":"text",
        "rtype":"group",
        "room_id":1,
        "sender_id":1,
        "content":"",
        "at_ids":[2, 3]
    }
}
```

#### 响应

```json
{
    "op":1,
    "data": {
        "mtype":"text",
        "rtype":"group",
        "room_id":1,
        "sender_id":1,
        "content":"",
        "related_message":{
        	"mtype":"text",
            "msg_op":1,
        	"room_id":1,
        	"sender_id":1,
        	"content":"",
        	"index":20,
        	"message_id":1,
        	"time":"",
            "recalled":false,
            "read":false,
            "at_ids":[2, 3]
        }
    }
}
```

### 2 - 群主或群管理员邀请新的群成员（已完成） 

#### 发请求时机

​	群主或群管理员点击了 rtype 为 "group" 的群聊成员页的 "+" 按钮，然后选中一个自己的好友

#### 请求

```json
{
	"op": 2,
    "data": {
        "room_id": 1,
        "inviter_id": 1,
        "invitee_id":2
    }
}
```

#### 响应

```json
{
	"op": 2,
    "data": {
        "room_id": 1,
        "inviter_id": 1,
        "invitee_id":2,
        "room_name":"",
        "related_message":{
        	"mtype":"operation",
            "msg_op":2,
        	"room_id":1,
        	"sender_id":1,
        	"content":"... 邀请 ... 加入了群聊",
        	"index":20,
        	"message_id":1,
        	"time":"",
            "recalled":false,
            "read":false
        },
        "related_room": ROOM
    }
}
```

### 3 - 退出群（已完成）

#### 发请求时机

​	用户在群聊成员页点击"删除并退出群聊"按钮

#### 请求

```json
{
    "op":3,
    "data":{
        "room_id":1,
        "old_member_id":1
    }
}
```

#### 响应

```json
{
    "op":3,
    "data":{
        "room_id":1,
        "old_member_id":1,
        "related_message":{
        	"mtype":"operation",
            "msg_op":3,
        	"room_id":1,
        	"sender_id":1,
        	"content":"... 退出了群聊",
        	"index":20,
        	"message_id":1,
        	"time":"",
             "recalled":false,
             "read":false
        }
    }
}
```

### 4 - 踢出群聊（已完成）

#### 发请求时机

​	群主、群管理员点击群聊成员页的 "-" 按钮

#### 请求

```json
{
    "op":4,
    "data":{
        "room_id":1,
        "sender_id":1,
        "kicked_id":2
    }
}
```

#### 响应

```json
{
    "op":4,
    "data":{
        "room_id":1,
        "sender_id":1,
        "kicked_id":2,
        "related_message":{
        	"mtype":"operation",
            "msg_op":4,
        	"room_id":1,
        	"sender_id":1,
        	"content":"... 被 ... 踢出群聊",
        	"index":20,
        	"message_id":1,
        	"time":"",
             "recalled":false,
             "read":false
        }        
    }
}
```

### 5 - 修改群名（已完成）

#### 发请求时机

​	群成员点击群聊成员页的"修改群名"按钮

#### 请求

```json
{
    "op":5,
    "data":{
        "room_id":1,
        "sender_id":1,
        "new_name":"锐科5交流群"
    }
}
```

#### 响应

```json
{
    "op":5,
    "data":{
        "room_id":1,
        "sender_id":1,
        "new_name":"锐科5交流群",
        "related_message":{
        	"mtype":"operation",
            "msg_op":5,
        	"room_id":1,
        	"sender_id":1,
        	"content":"... 将群名修改为 ...",
        	"index":20,
        	"message_id":1,
        	"time":"",
             "recalled":false,
             "read":false
        }
    }
}
```

### 6 - 修改群头像

#### 发请求时机

​	群成员点击群聊成员页的"修改群头像"按钮

#### 请求

还没想好，之后补全

#### 响应

### 7 - 解散群（协议已修改，代码未完成）

#### 发请求时机

​	群主点击 rtype 为 "group" 的群聊成员页中的"解散群聊" 按钮

#### 请求

```json
{
	"op":7,
    "data":{
        "room_id":1,
        "rtype":"group",
        "sender_id":1
    }
}
```

#### 响应

```json
{
	"op":7,
    "data":{
        "room_id":1,
        "rtype":"group",
        "sender_id":1,
        "related_message":{
        	"mtype":"operation",
            "msg_op":7,
        	"room_id":1,
        	"sender_id":1,
        	"content":"群主 ... 已解散群聊",
        	"index":20,
        	"message_id":1,
        	"time":"",
             "recalled":false,
             "read":false
        }
    }
}
```

### 8 - 删除消息（已完成）

#### 发请求时机

​	用户右键某消息，点击删除

#### 请求

```json
{
	"op":8,
    "data":{
        "room_id":1,
        "rtype":"group",
        "sender_id":1,
        "message_id":10000
    }
}
```

#### 响应

```json
{
	"op":8,
    "data":{
        "room_id":1,
        "rtype":"group",
        "sender_id":1,
        "message_id":10000
    }
}
```

#### 备注

- 方便起见，self_room中的消息不可撤回，不可删除

### 9 - 撤回消息（已完成）

#### 规则（这些功能文档中规定的…… sad）

> 群主与群管理员可以⽆视撤回消息的时间约束直接撤回消息
>
> 群主可以撤回任何消息，群管理员仅能撤回⾮群主、⾮群管理员的群成员的消息
>
> 普通成员撤回自己的消息时有两分钟的时间限制

#### 发请求条件

​	用户右键选择消息，点击撤回

#### 请求

```json
{
    "op":9,
    "data":{
        "room_id":1,
        "rtype":"group",
        "sender_id":1,
        "index":500
    }
}
```

#### 响应

```json
{
    "op":9,
    "data":{
        "room_id":1,
        "rtype":"group",
        "sender_id":1,
        "index":500,
        "related_message":MESSAGE
    }
}
```

#### 备注

- 撤回并不是消息被删了，而是消息的内容变成了"... 撤回了一条消息"
- 前端用响应中的"related_message"**替换**原来那条消息
- 方便起见，self_room中的消息不可撤回，不可删除
- 已经撤回的消息不允许删除

### 10 - 设置管理员（已完成）

#### 发请求条件

​	群主在群聊成员表中右键某普通成员，点击“设置为管理员”

#### 请求

```json
{
    "op":10,
    "data":{
        "room_id":1,
        "sender_id":1,
        "new_admin_id":2,
    }
}
```

#### 响应

```json
{
    "op":10,
    "data":{
        "room_id":1,
        "sender_id":1,
        "new_admin_id":2,
        "related_message":{
        	"mtype":"operation",
            "msg_op":10,
        	"room_id":1,
        	"sender_id":1,
        	"content":"群主 ... 将 ... 添加为群管理员",
        	"index":20,
        	"message_id":1,
        	"time":"",
             "recalled":false,
             "read":false
        }
    }
}
```

### 11 - 取消管理员（已完成）

#### 发请求条件

​	群主在群聊成员表中右键某管理员，点击“取消群管理员”

#### 请求

```json
{
    "op":11,
    "data":{
        "room_id":1,
        "sender_id":1,
        "old_admin_id":2
    }
}
```

#### 响应

```json
{
    "op":11,
    "data":{
        "room_id":1,
        "sender_id":1,
        "old_admin_id":2,
        "time":"",
        "related_message":{
        	"mtype":"operation",
            "msg_op":11,
        	"room_id":1,
        	"sender_id":1,
        	"content":"群主 ... 取消了 ... 的群管理员资格",
        	"index":20,
        	"message_id":1,
        	"time":"",
             "recalled":false,
             "read":false
        }
    }
}
```

###  12 - 转让群主（已完成）

#### 发请求条件

​	群主在群聊成员表中右键某群成员，点击“转让群主”。（最好有个确定弹窗）

#### 请求

```json
{
	"op":12,
    "data":{
        "room_id":1,
        "sender_id":1,
        "new_owner_id":2
    }
}
```

#### 响应

```json
{
	"op":12,
    "data":{
        "room_id":1,
        "sender_id":1,
        "new_owner_id":2,
        "time":"",
        "related_message":"...已成为新群主"
    }
}
```

### 13 - 修改群公告（未完成）

#### 发请求条件

​	群主或群管理员在成员页的群公告中点击编辑按钮，修改后，点击保存

#### 请求

```json
{
	"op":13,
    "data":{
        "room_id":1,
        "sender_id":1,
        "announcement":""
    }
}
```

#### 响应

```json
{
	"op":13,
    "data":{
        "room_id":1,
        "sender_id":1,
        "announcement":"",
        "time":"",
        "related_message":"@所有人：\n ..."
    }
}
```

### 14 - 发送好友请求（已完成）

#### 发请求条件

​	inviter在添加好友界面，指定了id和name中的任意一个，然后点击“发送好友申请”按钮

#### 请求

```json
{
    "op":14,
    "data":{
        "inviter_id":1, 
        "invitee_name":"",
        "invitee_id":2,
        "hello_content":"你好"
    }
}
```

#### 响应

```json
{
    "op":14,
    "data":{
        "inviter_id":1, 
        "invitee_name":"",
        "invitee_id":2,
        "hello_content":"你好，我有问题想请教一下",
        "rtype":"self",
        "related_message":{
        	"mtype":"operation",
            "msg_op":14,
        	"room_id":1,
        	"sender_id":1,
            "receiver_id":2, 
        	"content":"[用户 ... 想申请成为您的好友] 你好，我有问题想请教一下",
        	"index":20,
        	"message_id":1,
        	"time":"",
             "recalled":false,
             "read":false
        }
    }
}
```

#### 异常响应

1. 响应 data 字段的 invitee_id 为 -1，说明找不到invitee
2. 除此之外若发生其他错误， `response ["data"]["error"]`存在且非空（例如两人已经是好友）

### 15 - 处理好友请求（已完成）

#### 发请求条件

​	invitee在处理好友请求界面，点击“同意”或“拒绝”按钮

#### 请求

```json
{
    "op":15,
    "data":{
        "invitee_id":2, 
        "inviter_id":1,
        "is_accept":true
    }
}
```

#### 响应

```json
{
	"op":15,
    "data":{
        "invitee_id":2,
        "inviter_id":1,
        "is_accept": true,
        "related_message":{
        	"mtype":"operation",
            "msg_op":14,
        	"room_id":1,
        	"sender_id":1,
            "receiver_id": 2, 
        	"content":"[处理好友请求] 用户 ... 接收/拒绝了您的好友申请",
        	"index":20,
        	"message_id":1,
        	"time":"",
             "recalled":false,
             "read":false
        }
    }
}
```

1. 加上好友后，后端会自动创建私聊，并发给前端，参见“创建群”响应格式
2. 如果两人已经是好友，直接返回error（`response ["data"]["error"]`存在且非空）

### 16 - 删除好友（已完成）

#### 发请求条件

​	deletor在私聊页面的成员页中，点击“清空记录并删除好友”按钮

#### 请求

```json
{
	"op":16,
    "data":{
        "deleter_id": 1,
        "deleted_id": 2
    }
}
```

#### 响应

```json
{
	"op":16,
    "data":{
        "deleter_id": 1,
        "deleted_id": 2,
        "contact_deleted": true
    }
}
```

#### 备注

- 好友删除后私聊也一并删除，后端会向前端发送一个解散群聊的响应体，
- 好友删除成功后双方网页弹窗提醒

### 17 - 加载所有群聊基本信息（已完成）

#### 发请求条件

​	刚登录

#### 请求

```json
{
	"op":17,
    "data":{
        "sender_id": 1
    }
}
```

#### 响应

```json
{
    "op":17,
    "data":{
        "sender_id": 1,
        "rooms":list[ROOM]
    }
}
```

### 18 -  加载某一个群聊的所有历史消息（已完成）

#### 发请求条件

​	登录后**第一次**在左侧点击某群聊

#### 请求

```json
{
	"op":18,
    "data":{
        "sender_id": 1,
        "room_id": 1,
    }
}
```

#### 响应

```json
{
	"op":18,
    "data":{
        "sender_id": 1,
        "room_id": 1,
	    "messages": list[MESSAGE]
    }
}
```

### 19 - 阅读了某一个群聊的所有消息（协议已修改，代码未完成）

#### 发请求时机

​	用户点击左侧某未读消息数不为0的群聊

#### 请求

```json
{
    "op":19,
    "data":{
        "sender_id":1,
        "room_id":1
    }
}
```

#### 响应

```json
{
	"op":19,
    "data":{
        "sender_id":1,
        "room_id":1,
    }
}
```

### 20 - 加载所有联系人信息（已完成）

#### 发请求时机

​	刚登录

#### 请求

```json
{
    "op":20,
    "data":{
        "sender_id":1
    }
}
```

#### 响应

```json
{
    "op":20,
    "data":{
        "sender_id":1,
        "contacts":list[USER]
    }
}
```

### 21 - 设置消息免打扰（已完成）

#### 发请求时机

​	用户在群聊成员页中勾选“消息免打扰”

#### 请求

```json
{
    "op":21,
    "data":{
        "sender_id":1,
        "room_id":1
    }
}
```

#### 响应

```json
{
    "op":21,
    "data":{
        "sender_id":1,
        "room_id":1
    }
}
```

### 22 - 取消消息免打扰（已完成）

#### 发请求时机

​	用户在群聊成员页中取消勾选“消息免打扰”

#### 请求

```json
{
    "op":22,
    "data":{
        "sender_id":1,
        "room_id":1
    }
}
```

#### 响应

```json
{
    "op":22,
    "data":{
        "sender_id":1,
        "room_id":1
    }
}
```

### 23 - 置顶聊天（已完成）

#### 发请求时机

​	用户在群聊成员页中勾选“置顶聊天”

#### 请求

```json
{
    "op":23,
    "data":{
        "sender_id":1,
        "room_id":1
    }
}
```

#### 响应

```json
{
    "op":23,
    "data":{
        "sender_id":1,
        "room_id":1
    }
}
```

### 24 - 取消置顶聊天（已完成）

#### 发请求时机

​	用户在群聊成员页中取消勾选“置顶聊天”

#### 请求

```json
{
    "op":24,
    "data":{
        "sender_id":1,
        "room_id":1
    }
}
```

#### 响应

```json
{
    "op":24,
    "data":{
        "sender_id":1,
        "room_id":1
    }
}
```

### 25 - 审核入群请求（协议已修改，代码未完成）

#### 发请求时机

​	对于群主和群管理员，"... 请求邀请 ... 进入群聊"后面带有 "批准/不批准"按钮，按下按钮时发请求

#### 请求

```json
{
    "op":25,
    "data":{
        "sender_id":1,
        "room_id":1,
        "inviter_id":2,
        "invitee_id":3,
        "is_accept":true
    }   
}
```

#### 响应

```json
{
    "op":25,
    "data":{
        "sender_id":1,
        "room_id":1,
        "inviter_id":2,
        "invitee_id":3,
        "is_accept":true,
        "related_message": {
                "mtype":"operation",
                "msg_op":25,
                "room_id":1,
                "sender_id":1,
                "receiver_id":2, 
                "message_id":3,
                "index":20,
                "content":"经 ... 审核通过，... 邀请 ... 进入群聊",
                "time":"",
                "recalled":false,
                "read":true
        },
        "related_room": ROOM
    }   
}
```

### 26 - 用户注销（已完成）

#### 发请求时机

​	在自己的用户页中点击“注销账号”按钮并点“确定”

#### 请求

```json
{
    "op":26,
    "data":{
        "sender_id":1,
    }
}
```

#### 响应

```json
{
    "op":26,
    "data":{
        "sender_id":1,
        "account_deleted":true
    }
}
```

### 27 - 查看用户信息（已完成）

#### 发请求时机

功能和http请求中的查看用户信息完全一致，为方便前端，这里也提供了websocket请求

#### 请求

```json
{
    "op":27,
    "data":{
        "sender_id":1,
        "searching_id":2,
        "searching_name":""
    }
}
```

#### 响应

```json
{
    "op":27,
    "data":{
        "sender_id":1,
        "searching_id":2,
        "searching_name":"",
        "related_user":{
            "user_id":2,
            "user_name":"",
            "email":"",
            "image":"",
            "self_room_id":1
        },
        "is_contact": true
    }
}
```

#### 异常响应 & 备注

1. 如果没有找到user，则searching_id为-1
2. searching_id和searching_name请求中有一个就行，另一个key可以不写，如果都存在，以searching_id指定的用户为准

### 28 - 普通群成员邀请新的群成员 （协议已修改，代码未完成）

#### 发请求时机

​	普通群成员点击了 rtype 为 "group" 的群聊成员页的 "+" 按钮，然后选中了一个自己的好友

#### 请求

```json
{
	"op": 28,
    "data": {
        "room_id": 1,
        "inviter_id": 1,
        "invitee_id":2
    }
}
```

#### 响应

```json
{
	"op": 28,
    "data": {
        "room_id": 1,
        "inviter_id": 1,
        "invitee_id":2,
        "related_message": {
                "mtype":"operation",
                "msg_op":25,
                "room_id":1,
                "sender_id":1,
                "receiver_id":2, 
                "message_id":3,
                "index":20,
                "content":"... 想邀请 ... 进入群聊，审核中",
                "time":"",
                "recalled":false,
                "read":true
        }
    }
}
```

