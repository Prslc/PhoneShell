let fullData = {};
let currentMode = '';
let currentList = [];
  
function renderApps(data) {
    const container = document.getElementById("app-list");
    container.innerHTML = '';

    const enabledApps = [];
    const disabledApps = [];

    for (const [pkg, name] of Object.entries(data)) {
        if (!name || name.trim() === '') continue;  // 过滤无名称应用
        const card = document.createElement('div');
        card.className = 'app-card';
        card.setAttribute("data-name", name.toLowerCase());
        card.setAttribute("data-pkg", pkg.toLowerCase());
        card.innerHTML = `
            <div class="app-info">
                <div class="app-name">${name}</div>
                <div class="package">${pkg}</div>
            </div>
            <label class="switch">
                <input type="checkbox" data-pkg="${pkg}">
                <span class="slider"></span>
            </label>
        `;

        // 根据当前开关状态，将应用分类到启用或未启用列表
        const isChecked = currentList.includes(pkg);
        if (isChecked) {
            enabledApps.push(card);
        } else {
            disabledApps.push(card);
        }
    }

    enabledApps.forEach(card => container.appendChild(card));
    disabledApps.forEach(card => container.appendChild(card));
}

// 搜索过滤逻辑
function setupSearch() {
    const input = document.getElementById("search");
    input.addEventListener("input", () => {
        const keyword = input.value.trim().toLowerCase();
        document.querySelectorAll('.app-card').forEach(card => {
            const name = card.getAttribute("data-name");
            const pkg = card.getAttribute("data-pkg");
            if (name.includes(keyword) || pkg.includes(keyword)) {
                card.style.display = "flex";
            } else {
                card.style.display = "none";
            }
        });
    });
}

// 加载当前模式（白名单或黑名单）
function loadMode() {
    fetch("http://127.0.0.1:23333/api/maho/list", {
        method: 'GET',
        headers: {
            "Authorization": "node",
            "Content-Type": "application/json"
        }
    })
        .then(res => res.json())
        .then(data => {
            currentMode = data.mode;
            updateModeDisplay(); 
            loadWhitelistOrBlacklist(data); 
        })
        .catch(err => {
            console.error("获取模式失败：", err);
        });
}

// 更新页面上显示的模式
function updateModeDisplay() {
    const modeDisplay = document.getElementById("mode-display");
    modeDisplay.textContent = `${currentMode === 'white' ? '白名单模式' : '黑名单模式'}`;
}

// 加载应用列表和设置白名单或黑名单
fetch("http://127.0.0.1:23333/api/maho/labels", {
    method: 'GET',
    headers: {
        "Authorization": "node",
        "Content-Type": "application/json"
    }
})
    .then(response => {
        if (!response.ok) throw new Error("状态码：" + response.status);
        return response.json();
    })
    .then(data => {
        fullData = data;
        renderApps(data);  
        setupSearch();
        loadMode();   l
    })
    .catch(err => {
        document.getElementById("app-list").innerText = "加载失败：" + err;
    });

function loadWhitelistOrBlacklist(data) {
    const list = currentMode === 'white' ? data.white : data.black;
    currentList = Array.isArray(list) ? [...list] : [];
    renderApps(fullData);

    // 设置每个 switch 的初始状态
    document.querySelectorAll('input[type=checkbox]').forEach(sw => {
        const pkg = sw.dataset.pkg;
        sw.checked = currentList.includes(pkg);
    });

    // 添加事件监听，更新 currentList
    document.querySelectorAll('input[type=checkbox]').forEach(sw => {
        sw.addEventListener("change", (e) => {
            const pkg = e.target.dataset.pkg;
            if (e.target.checked) {
                currentList.push(pkg);
            } else {
                const index = currentList.indexOf(pkg);
                if (index !== -1) {
                    currentList.splice(index, 1);
                }
            }

            currentList.sort((a, b) => {
                const aChecked = document.querySelector(`input[data-pkg="${a}"]`).checked;
                const bChecked = document.querySelector(`input[data-pkg="${b}"]`).checked;
                return bChecked - aChecked;
            });

            console.log("当前列表：", currentList);
            UpdateAppList();
        });
    });
}

// 上传新列表
function UpdateAppList() {
    // console.log("上传数据：", { mode: currentMode, list: currentList });

    fetch("http://127.0.0.1:23333/api/maho/list/list", {
        method: 'PATCH',
        headers: {
            "Authorization": "node",
            "Content-Type": "application/json"
        },
        body: JSON.stringify({ mode: currentMode, list: currentList }),
    })
        .then(res => {
            if (!res.ok) {
                throw new Error('上传失败，状态码：' + res.status);
            }
            return res.json();
        })
        .then(data => {
            console.log("上传成功：", data);
        })
        .catch(err => {
            console.error("上传失败：", err);
        });
}

// 检测系统当前主题模式（浅色或深色）
function detectThemeMode() {
    const isDarkMode = window.matchMedia && window.matchMedia("(prefers-color-scheme: dark)").matches;
    if (isDarkMode) {
        document.body.classList.add("dark-mode");
    } else {
        document.body.classList.remove("dark-mode");
    }
}

// 监听系统主题变化
function listenForThemeChange() {
    const mediaQuery = window.matchMedia("(prefers-color-scheme: dark)");
    mediaQuery.addEventListener("change", (e) => {
        if (e.matches) {
            document.body.classList.add("dark-mode");
        } else {
            document.body.classList.remove("dark-mode");
        }
    });
}

detectThemeMode();
listenForThemeChange();
