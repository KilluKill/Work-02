// Основной JavaScript файл для Minecraft сервера

// Инициализация при загрузке страницы
document.addEventListener('DOMContentLoaded', function() {
    initializeApp();
});

// Основная инициализация
function initializeApp() {
    // Анимации при скролле
    initScrollAnimations();
    
    // Обновление статистики сервера
    updateServerStats();
    setInterval(updateServerStats, 30000); // каждые 30 секунд
    
    // Инициализация tooltips
    initTooltips();
    
    // Плавный скролл
    initSmoothScroll();
    
    // Lazy loading изображений
    initLazyLoading();
}

// Анимации при скролле
function initScrollAnimations() {
    const observer = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                entry.target.classList.add('fade-in-up');
            }
        });
    }, {
        threshold: 0.1,
        rootMargin: '0px 0px -50px 0px'
    });

    // Наблюдаем за элементами
    document.querySelectorAll('.feature-card, .product-card, .stat-card, .news-card').forEach(el => {
        observer.observe(el);
    });
}

// Обновление статистики сервера
async function updateServerStats() {
    try {
        const response = await fetch('/api/server-status');
        const data = await response.json();
        
        if (data.online) {
            // Обновляем счетчики онлайна
            updateElement('online-count', data.players.online);
            updateElement('footer-online', data.players.online);
            updateElement('hero-online', data.players.online);
            updateElement('stat-online', data.players.online);
            
            // Обновляем статус сервера
            const statusElements = document.querySelectorAll('#server-status .badge');
            statusElements.forEach(el => {
                el.className = 'badge bg-success';
                el.innerHTML = '<i class="fas fa-circle me-1"></i>' + data.players.online + ' онлайн';
            });
        } else {
            // Сервер оффлайн
            const statusElements = document.querySelectorAll('#server-status .badge');
            statusElements.forEach(el => {
                el.className = 'badge bg-danger';
                el.innerHTML = '<i class="fas fa-times-circle me-1"></i>Оффлайн';
            });
        }
    } catch (error) {
        console.error('Ошибка получения статистики сервера:', error);
    }
}

// Обновление элемента по ID
function updateElement(id, value) {
    const element = document.getElementById(id);
    if (element) {
        // Анимация изменения числа
        const currentValue = parseInt(element.textContent) || 0;
        const newValue = parseInt(value) || 0;
        
        if (currentValue !== newValue) {
            animateNumber(element, currentValue, newValue, 1000);
        }
    }
}

// Анимация изменения числа
function animateNumber(element, start, end, duration) {
    const startTime = performance.now();
    const difference = end - start;
    
    function updateNumber(currentTime) {
        const elapsed = currentTime - startTime;
        const progress = Math.min(elapsed / duration, 1);
        
        const currentValue = Math.floor(start + difference * easeOutCubic(progress));
        element.textContent = currentValue;
        
        if (progress < 1) {
            requestAnimationFrame(updateNumber);
        }
    }
    
    requestAnimationFrame(updateNumber);
}

// Функция плавности анимации
function easeOutCubic(t) {
    return 1 - Math.pow(1 - t, 3);
}

// Инициализация tooltips
function initTooltips() {
    const tooltipTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="tooltip"]'));
    tooltipTriggerList.map(function (tooltipTriggerEl) {
        return new bootstrap.Tooltip(tooltipTriggerEl);
    });
}

// Плавный скролл
function initSmoothScroll() {
    document.querySelectorAll('a[href^="#"]').forEach(anchor => {
        anchor.addEventListener('click', function (e) {
            e.preventDefault();
            const target = document.querySelector(this.getAttribute('href'));
            if (target) {
                target.scrollIntoView({
                    behavior: 'smooth',
                    block: 'start'
                });
            }
        });
    });
}

// Lazy loading изображений
function initLazyLoading() {
    const images = document.querySelectorAll('img[data-src]');
    const imageObserver = new IntersectionObserver((entries, observer) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                const img = entry.target;
                img.src = img.dataset.src;
                img.classList.remove('lazy');
                imageObserver.unobserve(img);
            }
        });
    });

    images.forEach(img => imageObserver.observe(img));
}

// Функция показа уведомлений
function showToast(message, type = 'info', duration = 5000) {
    const toast = document.getElementById('toast');
    const toastMessage = document.getElementById('toast-message');
    
    if (!toast || !toastMessage) return;
    
    // Устанавливаем сообщение
    toastMessage.textContent = message;
    
    // Устанавливаем тип уведомления
    const typeClasses = {
        'success': 'border-success',
        'error': 'border-danger',
        'warning': 'border-warning',
        'info': 'border-info'
    };
    
    // Очищаем предыдущие классы
    Object.values(typeClasses).forEach(cls => toast.classList.remove(cls));
    
    // Добавляем новый класс
    toast.classList.add(typeClasses[type] || typeClasses.info);
    
    // Показываем уведомление
    const bsToast = new bootstrap.Toast(toast, {
        delay: duration
    });
    bsToast.show();
    
    // Добавляем анимацию
    if (type === 'success') {
        toast.classList.add('success-animation');
        setTimeout(() => toast.classList.remove('success-animation'), 600);
    } else if (type === 'error') {
        toast.classList.add('error-animation');
        setTimeout(() => toast.classList.remove('error-animation'), 600);
    }
}

// Копирование IP адреса
function copyIP() {
    const ip = 'play.craftserver.ru';
    
    if (navigator.clipboard) {
        navigator.clipboard.writeText(ip).then(() => {
            showToast('IP адрес скопирован в буфер обмена!', 'success');
            
            // Анимация кнопки
            const buttons = document.querySelectorAll('button[onclick="copyIP()"]');
            buttons.forEach(btn => {
                const originalText = btn.innerHTML;
                btn.innerHTML = '<i class="fas fa-check me-2"></i>Скопировано!';
                btn.classList.add('success-animation');
                
                setTimeout(() => {
                    btn.innerHTML = originalText;
                    btn.classList.remove('success-animation');
                }, 2000);
            });
        }).catch(() => {
            fallbackCopyIP(ip);
        });
    } else {
        fallbackCopyIP(ip);
    }
}

// Запасной способ копирования
function fallbackCopyIP(text) {
    const textArea = document.createElement('textarea');
    textArea.value = text;
    textArea.style.position = 'fixed';
    textArea.style.left = '-999999px';
    textArea.style.top = '-999999px';
    document.body.appendChild(textArea);
    textArea.focus();
    textArea.select();
    
    try {
        document.execCommand('copy');
        showToast('IP адрес скопирован в буфер обмена!', 'success');
    } catch (err) {
        showToast('Не удалось скопировать IP адрес', 'error');
    }
    
    document.body.removeChild(textArea);
}

// Функция выхода
function logout() {
    fetch('/logout', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        }
    })
    .then(response => response.json())
    .then(data => {
        if (data.success) {
            showToast('Вы успешно вышли из аккаунта', 'success');
            setTimeout(() => {
                window.location.href = '/';
            }, 1000);
        } else {
            showToast('Ошибка при выходе', 'error');
        }
    })
    .catch(error => {
        console.error('Error:', error);
        showToast('Ошибка подключения к серверу', 'error');
    });
}

// Валидация форм
function validateForm(form) {
    let isValid = true;
    const inputs = form.querySelectorAll('input[required], select[required], textarea[required]');
    
    inputs.forEach(input => {
        if (!input.value.trim()) {
            showFieldError(input, 'Это поле обязательно для заполнения');
            isValid = false;
        } else {
            clearFieldError(input);
            
            // Дополнительная валидация
            if (input.type === 'email' && !isValidEmail(input.value)) {
                showFieldError(input, 'Введите корректный email адрес');
                isValid = false;
            }
            
            if (input.name === 'minecraft_username' && !isValidMinecraftUsername(input.value)) {
                showFieldError(input, 'Некорректный Minecraft ник (3-16 символов, только буквы, цифры и _)');
                isValid = false;
            }
            
            if (input.type === 'password' && input.value.length < 6) {
                showFieldError(input, 'Пароль должен содержать минимум 6 символов');
                isValid = false;
            }
        }
    });
    
    return isValid;
}

// Показать ошибку поля
function showFieldError(input, message) {
    clearFieldError(input);
    
    input.classList.add('is-invalid');
    const errorDiv = document.createElement('div');
    errorDiv.className = 'invalid-feedback';
    errorDiv.textContent = message;
    input.parentNode.appendChild(errorDiv);
}

// Очистить ошибку поля
function clearFieldError(input) {
    input.classList.remove('is-invalid');
    const errorDiv = input.parentNode.querySelector('.invalid-feedback');
    if (errorDiv) {
        errorDiv.remove();
    }
}

// Валидация email
function isValidEmail(email) {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return emailRegex.test(email);
}

// Валидация Minecraft ника
function isValidMinecraftUsername(username) {
    const usernameRegex = /^[a-zA-Z0-9_]{3,16}$/;
    return usernameRegex.test(username);
}

// Форматирование числа с разделителями
function formatNumber(num) {
    return num.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ' ');
}

// Форматирование времени
function formatTime(timestamp) {
    const date = new Date(timestamp);
    return date.toLocaleString('ru-RU', {
        year: 'numeric',
        month: 'long',
        day: 'numeric',
        hour: '2-digit',
        minute: '2-digit'
    });
}

// Дебаунс функция
function debounce(func, wait) {
    let timeout;
    return function executedFunction(...args) {
        const later = () => {
            clearTimeout(timeout);
            func(...args);
        };
        clearTimeout(timeout);
        timeout = setTimeout(later, wait);
    };
}

// Троттлинг функция
function throttle(func, limit) {
    let lastFunc;
    let lastRan;
    return function() {
        const context = this;
        const args = arguments;
        if (!lastRan) {
            func.apply(context, args);
            lastRan = Date.now();
        } else {
            clearTimeout(lastFunc);
            lastFunc = setTimeout(function() {
                if ((Date.now() - lastRan) >= limit) {
                    func.apply(context, args);
                    lastRan = Date.now();
                }
            }, limit - (Date.now() - lastRan));
        }
    }
}

// Обработка ошибок AJAX
function handleAjaxError(error, customMessage = 'Произошла ошибка') {
    console.error('AJAX Error:', error);
    
    let message = customMessage;
    if (error.response) {
        try {
            const errorData = JSON.parse(error.response);
            message = errorData.error || errorData.message || customMessage;
        } catch (e) {
            // Ignore JSON parse error
        }
    }
    
    showToast(message, 'error');
}

// Загрузка контента с индикатором
function loadWithIndicator(element, url, options = {}) {
    const originalContent = element.innerHTML;
    element.innerHTML = '<div class="text-center"><div class="loading"></div> Загрузка...</div>';
    
    return fetch(url, options)
        .then(response => {
            if (!response.ok) {
                throw new Error(`HTTP error! status: ${response.status}`);
            }
            return response.text();
        })
        .then(html => {
            element.innerHTML = html;
            return html;
        })
        .catch(error => {
            element.innerHTML = originalContent;
            handleAjaxError(error, 'Ошибка загрузки контента');
            throw error;
        });
}

// Инициализация счетчиков
function initCounters() {
    const counters = document.querySelectorAll('[data-count]');
    
    const counterObserver = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                const counter = entry.target;
                const target = parseInt(counter.dataset.count);
                animateNumber(counter, 0, target, 2000);
                counterObserver.unobserve(counter);
            }
        });
    });
    
    counters.forEach(counter => counterObserver.observe(counter));
}

// Инициализация параллакс эффекта
function initParallax() {
    const parallaxElements = document.querySelectorAll('[data-parallax]');
    
    if (parallaxElements.length > 0) {
        const handleScroll = throttle(() => {
            const scrolled = window.pageYOffset;
            
            parallaxElements.forEach(element => {
                const speed = element.dataset.parallax || 0.5;
                const yPos = -(scrolled * speed);
                element.style.transform = `translateY(${yPos}px)`;
            });
        }, 10);
        
        window.addEventListener('scroll', handleScroll);
    }
}

// Инициализация при загрузке DOM
document.addEventListener('DOMContentLoaded', function() {
    initCounters();
    initParallax();
});

// Экспорт функций для глобального использования
window.showToast = showToast;
window.copyIP = copyIP;
window.logout = logout;
window.validateForm = validateForm;