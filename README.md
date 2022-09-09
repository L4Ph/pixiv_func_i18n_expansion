# Pixiv Func I18n Generator

### 要新增一种语言时请提交一个PR

包括以下内容:

1. 命名为`$locale`的json文件(例如`zh_CN.json`) 到`/i18n_expansion/`目录
2. 命名为GitHub用户名的图片(例如`username.png`,`username.gif`) 到`/avatars/`目录
3. 在`/i18n_expansion/expansions.json`中添加一个值(`${locale}.json`) 例如

```json
[
  "zh_CN.json"
]
```

#### 示例

```json
{
  "locale": "zh_CN",
  "title": "简体中文",
  "versionCode": 0,
  "author": "name",
  "github": "username",
  "avatar": "avatars/0.png",
  "data": {
  }
}
```

每次更新时`versionCode`+1  
使用生成器生成`data`段并填充

#### 由`Pixiv Func`项目加载