import { exec } from "./kernelsu.js";

const outputElement = document.getElementById("output");
const refreshButton = document.getElementById("refresh");
const searchInput = document.getElementById("search");
const logLevelSelect = document.getElementById("log-level");

let originalLog = ""; // 存储完整日志内容

async function findLogPath() {
    try {
        const { errno, stdout, stderr } = await exec(`

            logtype="$(awk -F ': ' '/"logPrintMode"/ {gsub(/[^0-9]/, "", $2); print $2}' /data/system/Freezer/GlobalSettings.json)"

            # 获取日志类型
            if [ $logtype -eq 0 ]; then
                logtype="文件"
                logpath="/data/system/Freezer/log/current.log"
            elif [ $logtype -eq 1 ]; then
                logtype="框架"
                logpath="$(ls -t /data/adb/lspd/log/module* | head -n 1)"
            elif [ $logtype -eq 2 ]; then
                logtype="关闭"
            else
                logtype="未知"
            fi

            echo "$logpath"
        `);

        if (errno === 0 && stdout.trim()) {
            return stdout.trim(); // 返回日志文件路径
        } else {
            console.error("Failed to find log path:", stderr);
            return null;
        }
    } catch (error) {
        console.error("Error executing findLogPath:", error);
        return null;
    }
}

async function loadFile() {
    outputElement.textContent = "Loading...";

    const filePath = await findLogPath();
    if (!filePath) {
        outputElement.textContent = "❌ 未找到日志文件路径";
        return;
    }

    try {
        const { errno, stdout, stderr } = await exec(`cat ${filePath}`);
        if (errno === 0) {
            let logContent = stdout || "(文件为空)";

            // 如果日志来源于 LSPosed（模块日志），进行专门处理
            if (filePath.includes("/data/adb/lspd/log/module")) {
                logContent = processLSPosedLog(logContent);
            }

            originalLog = logContent;
            searchLog();
        } else {
            outputElement.textContent = "❌ Error: " + stderr;
        }
    } catch (error) {
        outputElement.textContent = "⚠️ Execution failed: " + error.message;
    }
}

// 处理 LSPosed 日志，仅保留 Freezer 相关日志
function processLSPosedLog(logContent) {
    return logContent
        .split("\n")
        .filter(line => line.includes("Freezer-Log")) // 仅保留 Freezer 相关日志
        .map(line => {
            // 匹配时间戳 + Freezer-Log 后的内容
            const match = line.match(/^\[\s*(\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3})\s*.*?\] Freezer-Log (.*)$/);
            if (match) {
                const timestamp = match[1];
                const logMessage = match[2];
                return `${formatTimestamp(timestamp)} ${logMessage}`;
            }
            return null; // 过滤掉不符合格式的行
        })
        .filter(Boolean) // 移除 null 值
        .join("\n") || "(未找到 Freezer 相关日志)";
}

function formatTimestamp(timestamp) {
    return timestamp.replace("T", " ").split(".")[0];
}


// 过滤日志内容
function searchLog() {
    const keyword = searchInput.value.trim().toLowerCase();
    const logLevel = logLevelSelect.value; // 选中的日志级别

    const filteredLines = originalLog
        .split("\n")
        .filter(line => {
            const matchesLevel = logLevel === "" || line.includes(logLevel);
            const matchesKeyword = keyword === "" || line.toLowerCase().includes(keyword);
            return matchesLevel && matchesKeyword;
        });

    displayLog(filteredLines.join("\n") || "(无匹配日志)");
}

// 显示日志
function displayLog(content) {
    outputElement.textContent = content;
}

// 事件监听
refreshButton.addEventListener("click", loadFile);
searchInput.addEventListener("input", searchLog);
logLevelSelect.addEventListener("change", searchLog);

// 初始加载日志
loadFile();