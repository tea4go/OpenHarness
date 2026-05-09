# Web搜索工具

<cite>
**本文档引用的文件**
- [web_search_tool.py](file://src/openharness/tools/web_search_tool.py)
- [web_fetch_tool.py](file://src/openharness/tools/web_fetch_tool.py)
- [network_guard.py](file://src/openharness/utils/network_guard.py)
- [base.py](file://src/openharness/tools/base.py)
- [test_web_fetch_tool.py](file://tests/test_tools/test_web_fetch_tool.py)
</cite>

## 目录
1. [简介](#简介)
2. [项目结构](#项目结构)
3. [核心组件](#核心组件)
4. [架构概览](#架构概览)
5. [详细组件分析](#详细组件分析)
6. [依赖关系分析](#依赖关系分析)
7. [性能考虑](#性能考虑)
8. [安全与反爬虫策略](#安全与反爬虫策略)
9. [使用场景与示例](#使用场景与示例)
10. [故障排除指南](#故障排除指南)
11. [结论](#结论)

## 简介

Web搜索工具是OpenHarness框架中的两个核心网络工具，专门设计用于执行Web搜索和网页抓取操作。这些工具提供了安全、可靠的网络访问能力，支持异步操作，并内置了完整的安全防护机制。

**Web搜索工具**（web_search_tool）负责执行搜索引擎查询，解析搜索结果页面，提取标题、URL和摘要信息。**Web抓取工具**（web_fetch_tool）则专注于单个网页的内容抓取，将HTML内容转换为可读的纯文本格式。

这两个工具都基于统一的网络守护机制，确保所有外部网络请求都经过严格的安全验证和限制。

## 项目结构

Web搜索工具位于OpenHarness项目的工具模块中，采用清晰的分层架构：

```mermaid
graph TB
subgraph "工具模块"
A[web_search_tool.py<br/>搜索引擎工具]
B[web_fetch_tool.py<br/>网页抓取工具]
C[base.py<br/>基础工具抽象]
end
subgraph "安全模块"
D[network_guard.py<br/>网络守护]
end
subgraph "测试模块"
E[test_web_fetch_tool.py<br/>工具测试]
end
A --> D
B --> D
A --> C
B --> C
E --> A
E --> B
```

**图表来源**
- [web_search_tool.py:1-119](file://src/openharness/tools/web_search_tool.py#L1-L119)
- [web_fetch_tool.py:1-118](file://src/openharness/tools/web_fetch_tool.py#L1-L118)
- [network_guard.py:1-128](file://src/openharness/utils/network_guard.py#L1-L128)

**章节来源**
- [web_search_tool.py:1-119](file://src/openharness/tools/web_search_tool.py#L1-L119)
- [web_fetch_tool.py:1-118](file://src/openharness/tools/web_fetch_tool.py#L1-L118)
- [network_guard.py:1-128](file://src/openharness/utils/network_guard.py#L1-L128)

## 核心组件

### Web搜索工具（WebSearchTool）

WebSearchTool是一个专门的搜索引擎工具，提供以下核心功能：

- **搜索查询处理**：支持自定义查询参数和结果数量限制
- **结果解析**：从HTML页面中提取标题、URL和摘要信息
- **链接标准化**：处理重定向链接和URL规范化
- **安全防护**：通过网络守护机制确保请求安全性

### Web抓取工具（WebFetchTool）

WebFetchTool专注于单个网页的内容抓取和处理：

- **HTTP请求处理**：支持异步HTTP请求和重定向跟踪
- **内容下载**：获取网页内容并进行适当的格式转换
- **HTML到文本转换**：将复杂的HTML结构转换为简洁的纯文本
- **内容截断**：根据配置限制输出长度

**章节来源**
- [web_search_tool.py:27-66](file://src/openharness/tools/web_search_tool.py#L27-L66)
- [web_fetch_tool.py:33-71](file://src/openharness/tools/web_fetch_tool.py#L33-L71)

## 架构概览

两个工具共享相同的基础架构模式，体现了良好的软件设计原则：

```mermaid
sequenceDiagram
participant Client as 客户端
participant Tool as 工具实例
participant Guard as 网络守护
participant Search as 搜索引擎
participant Parser as 结果解析器
Client->>Tool : 执行工具调用
Tool->>Guard : 验证URL安全性
Guard-->>Tool : 返回验证结果
Tool->>Search : 发送HTTP请求
Search-->>Tool : 返回HTML响应
Tool->>Parser : 解析HTML内容
Parser-->>Tool : 返回结构化数据
Tool-->>Client : 返回处理结果
```

**图表来源**
- [web_search_tool.py:38-66](file://src/openharness/tools/web_search_tool.py#L38-L66)
- [web_fetch_tool.py:40-71](file://src/openharness/tools/web_fetch_tool.py#L40-L71)
- [network_guard.py:53-89](file://src/openharness/utils/network_guard.py#L53-L89)

## 详细组件分析

### Web搜索工具实现分析

WebSearchTool采用了模块化的实现方式，将不同的功能职责分离到独立的函数中：

```mermaid
classDiagram
class WebSearchTool {
+string name
+string description
+execute(arguments, context) ToolResult
+is_read_only(arguments) bool
-parse_search_results(body, limit) list
-normalize_result_url(raw_url) string
-clean_html(fragment) string
}
class WebSearchToolInput {
+string query
+int max_results
+string search_url
}
class NetworkGuard {
+validate_http_url(url) void
+ensure_public_http_url(url) void
+fetch_public_http_response(url, ...) Response
}
WebSearchTool --> WebSearchToolInput : 使用
WebSearchTool --> NetworkGuard : 依赖
WebSearchTool --> WebSearchTool : 组合
```

**图表来源**
- [web_search_tool.py:16-118](file://src/openharness/tools/web_search_tool.py#L16-L118)
- [network_guard.py:24-89](file://src/openharness/utils/network_guard.py#L24-L89)

#### 搜索结果解析算法

WebSearchTool使用正则表达式来解析HTML页面，提取搜索结果的关键信息：

```mermaid
flowchart TD
Start([开始解析]) --> ExtractSnippets["提取摘要片段"]
ExtractSnippets --> FindLinks["查找结果链接"]
FindLinks --> FilterResults{"过滤有效结果"}
FilterResults --> |是| ParseLink["解析链接属性"]
FilterResults --> |否| NextLink["检查下一个链接"]
ParseLink --> ExtractTitle["提取标题文本"]
ExtractTitle --> NormalizeURL["标准化URL"]
NormalizeURL --> CleanText["清理HTML标签"]
CleanText --> AddResult["添加到结果列表"]
AddResult --> CheckLimit{"达到限制?"}
CheckLimit --> |否| FindLinks
CheckLimit --> |是| ReturnResults["返回结果"]
NextLink --> FindLinks
ReturnResults --> End([结束])
```

**图表来源**
- [web_search_tool.py:69-103](file://src/openharness/tools/web_search_tool.py#L69-L103)

**章节来源**
- [web_search_tool.py:27-118](file://src/openharness/tools/web_search_tool.py#L27-L118)

### Web抓取工具实现分析

WebFetchTool提供了更复杂的内容处理能力，特别是HTML到文本的转换：

```mermaid
classDiagram
class WebFetchTool {
+string name
+string description
+execute(arguments, context) ToolResult
+is_read_only(arguments) bool
-html_to_text(html) string
-validate_url(url) tuple
}
class WebFetchToolInput {
+string url
+int max_chars
}
class HTMLTextExtractor {
+list parts
+int skip_depth
+handle_starttag(tag, attrs) void
+handle_endtag(tag) void
+handle_data(data) void
}
WebFetchTool --> WebFetchToolInput : 使用
WebFetchTool --> HTMLTextExtractor : 包含
WebFetchTool --> NetworkGuard : 依赖
```

**图表来源**
- [web_fetch_tool.py:26-117](file://src/openharness/tools/web_fetch_tool.py#L26-L117)

#### HTML到文本转换流程

WebFetchTool使用自定义的HTML解析器来高效地转换HTML内容：

```mermaid
flowchart TD
Start([开始转换]) --> InitParser["初始化HTML解析器"]
InitParser --> ParseHTML["解析HTML内容"]
ParseHTML --> SkipTags{"跳过脚本/样式?"}
SkipTags --> |是| SkipContent["跳过内容"]
SkipTags --> |否| ExtractText["提取文本内容"]
ExtractText --> CleanText["清理空白字符"]
CleanText --> CheckLength{"超过长度限制?"}
CheckLength --> |是| TruncateText["截断文本"]
CheckLength --> |否| FormatOutput["格式化输出"]
SkipContent --> ParseHTML
TruncateText --> FormatOutput
FormatOutput --> End([结束])
```

**图表来源**
- [web_fetch_tool.py:78-117](file://src/openharness/tools/web_fetch_tool.py#L78-L117)

**章节来源**
- [web_fetch_tool.py:33-117](file://src/openharness/tools/web_fetch_tool.py#L33-L117)

## 依赖关系分析

两个工具都依赖于统一的网络守护机制，形成了清晰的依赖层次：

```mermaid
graph TB
subgraph "应用层"
A[WebSearchTool]
B[WebFetchTool]
end
subgraph "工具抽象层"
C[BaseTool]
D[ToolExecutionContext]
E[ToolResult]
end
subgraph "安全层"
F[NetworkGuard]
G[NetworkGuardError]
end
subgraph "网络层"
H[httpx]
I[urllib.parse]
J[re]
K[html.parser]
end
A --> C
B --> C
A --> F
B --> F
F --> G
A --> H
B --> H
A --> I
B --> I
A --> J
B --> K
```

**图表来源**
- [web_search_tool.py:12-13](file://src/openharness/tools/web_search_tool.py#L12-L13)
- [web_fetch_tool.py:11-16](file://src/openharness/tools/web_fetch_tool.py#L11-L16)
- [network_guard.py:20-107](file://src/openharness/utils/network_guard.py#L20-L107)

**章节来源**
- [base.py:35-81](file://src/openharness/tools/base.py#L35-L81)
- [network_guard.py:1-128](file://src/openharness/utils/network_guard.py#L1-L128)

## 性能考虑

### 异步处理优化

两个工具都采用异步编程模型，提高了并发处理能力和资源利用率：

- **超时控制**：Web搜索工具设置20秒超时，Web抓取工具设置15秒超时
- **重定向限制**：最大5次重定向，防止无限循环
- **内存管理**：HTML解析器使用流式处理，避免内存溢出

### 正则表达式优化

Web搜索工具使用高效的正则表达式模式：

- **预编译模式**：减少重复编译开销
- **非贪婪匹配**：避免回溯陷阱
- **忽略大小写**：提高匹配效率

### 内存使用优化

Web抓取工具实现了多项内存优化策略：

- **流式HTML解析**：避免一次性加载整个HTML文档
- **条件跳过**：自动跳过脚本和样式内容
- **智能截断**：按字符数精确截断，避免多余处理

**章节来源**
- [web_search_tool.py:44-51](file://src/openharness/tools/web_search_tool.py#L44-L51)
- [web_fetch_tool.py:46-51](file://src/openharness/tools/web_fetch_tool.py#L46-L51)
- [test_web_fetch_tool.py:75-86](file://tests/test_tools/test_web_fetch_tool.py#L75-L86)

## 安全与反爬虫策略

### URL验证机制

网络守护系统提供了多层次的URL验证：

```mermaid
flowchart TD
Start([接收URL]) --> ValidateScheme["验证协议(http/https)"]
ValidateScheme --> CheckHost["检查主机名"]
CheckCredentials["检查嵌入凭据"]
ValidateScheme --> CheckHost
CheckHost --> CheckCredentials
CheckCredentials --> |发现凭据| Reject["拒绝请求"]
CheckCredentials --> |无凭据| ResolveIP["解析IP地址"]
ResolveIP --> CheckPublic["检查公共IP"]
CheckPublic --> |私有IP| Reject
CheckPublic --> |公共IP| Accept["接受请求"]
Reject --> End([结束])
Accept --> End
```

**图表来源**
- [network_guard.py:24-50](file://src/openharness/utils/network_guard.py#L24-L50)

### 请求头设置

两个工具都设置了合理的用户代理字符串：

- **Web搜索工具**：使用"OpenHarness/0.1"
- **Web抓取工具**：使用详细的浏览器标识符
- **防检测**：模拟真实浏览器行为

### 速率限制与防护

虽然当前实现没有内置的全局速率限制，但提供了以下防护措施：

- **重定向限制**：防止恶意重定向攻击
- **超时控制**：避免长时间占用连接
- **内容长度限制**：防止大文件下载

**章节来源**
- [network_guard.py:53-89](file://src/openharness/utils/network_guard.py#L53-L89)
- [web_search_tool.py:48-49](file://src/openharness/tools/web_search_tool.py#L48-L49)
- [web_fetch_tool.py:48-49](file://src/openharness/tools/web_fetch_tool.py#L48-L49)

## 使用场景与示例

### 技术文档检索

Web搜索工具特别适合技术文档的快速检索：

```python
# 示例：搜索OpenHarness文档
search_tool = WebSearchTool()
result = await search_tool.execute(
    WebSearchToolInput(
        query="OpenHarness installation guide",
        max_results=5
    )
)
```

### 新闻聚合

结合多个搜索查询，可以构建简单的新闻聚合系统：

```python
# 示例：搜索科技新闻
news_queries = [
    "latest technology news",
    "AI developments",
    "software updates"
]

for query in news_queries:
    result = await search_tool.execute(
        WebSearchToolInput(query=query, max_results=3)
    )
    # 处理和存储结果
```

### 实时信息获取

Web抓取工具适用于实时信息的获取和处理：

```python
# 示例：获取技术博客文章
fetch_tool = WebFetchTool()
result = await fetch_tool.execute(
    WebFetchToolInput(
        url="https://techblog.example.com/latest-post",
        max_chars=8000
    )
)
```

### 内容分析工作流

结合两个工具可以构建完整的内容分析流程：

```mermaid
flowchart LR
A[搜索查询] --> B[WebSearchTool]
B --> C[提取URL列表]
C --> D[WebFetchTool]
D --> E[HTML到文本转换]
E --> F[内容分析]
F --> G[结果输出]
```

**图表来源**
- [web_search_tool.py:56-66](file://src/openharness/tools/web_search_tool.py#L56-L66)
- [web_fetch_tool.py:58-71](file://src/openharness/tools/web_fetch_tool.py#L58-L71)

## 故障排除指南

### 常见错误类型

#### URL验证失败

当URL包含嵌入凭据或指向私有网络时，会触发验证错误：

```python
# 错误示例：包含嵌入凭据的URL
result = await fetch_tool.execute(
    WebFetchToolInput(url="https://user:pass@example.com/")
)
# 返回：web_fetch failed: URLs with embedded credentials are not allowed
```

#### 网络连接问题

HTTP错误和网络超时会导致请求失败：

```python
# 处理网络异常
try:
    result = await fetch_tool.execute(arguments)
except NetworkGuardError as e:
    print(f"网络请求失败: {e}")
```

#### 解析错误

HTML解析失败时，工具会返回错误状态：

```python
# 检查解析结果
if result.is_error:
    print(f"解析失败: {result.output}")
else:
    print("解析成功")
```

### 调试技巧

#### 启用详细日志

在开发环境中，可以通过修改工具的错误处理来获取更多信息：

```python
# 自定义错误处理
def handle_error(error):
    print(f"详细错误信息: {error}")
    print(f"错误类型: {type(error)}")
    return ToolResult(output=f"处理失败: {error}", is_error=True)
```

#### 测试环境配置

使用测试文件中的模式来模拟不同场景：

```python
# 参考测试文件中的模拟模式
# 在测试中使用monkeypatch替换网络调用
```

**章节来源**
- [test_web_fetch_tool.py:89-125](file://tests/test_tools/test_web_fetch_tool.py#L89-L125)
- [network_guard.py:20-50](file://src/openharness/utils/network_guard.py#L20-L50)

## 结论

Web搜索工具和Web抓取工具为OpenHarness框架提供了强大的网络访问能力。它们的设计体现了以下关键优势：

### 技术优势

- **安全性优先**：内置全面的URL验证和网络防护机制
- **性能优化**：异步处理、内存管理和高效的解析算法
- **可扩展性**：模块化设计，易于扩展和定制
- **可靠性**：完善的错误处理和超时控制

### 应用价值

- **搜索引擎集成**：支持多种搜索后端，包括私有搜索服务
- **内容获取**：提供灵活的网页内容抓取和处理能力
- **安全合规**：符合企业级安全要求，防止滥用和攻击
- **开发友好**：清晰的API设计和丰富的测试覆盖

### 未来发展方向

随着网络安全威胁的不断演变，建议进一步增强以下方面：

- **智能反爬虫**：实现更高级的请求伪装和频率控制
- **缓存机制**：添加内容缓存以提高性能和减少带宽消耗
- **监控告警**：集成使用统计和异常检测功能
- **配置管理**：提供更灵活的配置选项和环境变量支持

这两个工具为构建安全、可靠、高效的Web内容处理系统奠定了坚实的基础，是OpenHarness生态系统中的重要组成部分。