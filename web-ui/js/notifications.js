/**
 * PI-PVR Notification System
 * Provides a unified way to show notifications to users
 */

// Default settings
const DEFAULT_DURATION = 5000; // 5 seconds
const ANIMATION_DURATION = 300; // 0.3 seconds

// Track active notifications
let activeNotifications = [];
let nextId = 1;

/**
 * Show a notification to the user
 * @param {string} type - Type of notification: 'success', 'error', 'info', 'warning'
 * @param {string} message - The message to display
 * @param {number} [duration] - Duration in ms to show notification (0 = no auto-close)
 * @returns {number} Notification ID that can be used to dismiss it programmatically
 */
export function showNotification(type, message, duration = DEFAULT_DURATION) {
  const container = document.getElementById('notification-container');
  if (!container) return -1;
  
  // Create notification
  const id = nextId++;
  const notification = document.createElement('div');
  notification.className = `notification notification-${type}`;
  notification.dataset.id = id.toString();
  
  // Create content
  notification.innerHTML = `
    <div class="notification-content">${message}</div>
    <button class="notification-close">&times;</button>
  `;
  
  // Add to container
  container.appendChild(notification);
  
  // Setup close button
  const closeButton = notification.querySelector('.notification-close');
  closeButton.addEventListener('click', () => {
    dismissNotification(id);
  });
  
  // Track active notification
  activeNotifications.push({ id, element: notification, timerId: null });
  
  // Auto-dismiss after duration (if not 0)
  if (duration > 0) {
    const timerId = setTimeout(() => {
      dismissNotification(id);
    }, duration);
    
    // Update the timer ID
    const notificationObj = activeNotifications.find(n => n.id === id);
    if (notificationObj) {
      notificationObj.timerId = timerId;
    }
  }
  
  return id;
}

/**
 * Dismiss a notification by its ID
 * @param {number} id - Notification ID to dismiss
 */
export function dismissNotification(id) {
  const index = activeNotifications.findIndex(n => n.id === id);
  if (index === -1) return;
  
  const { element, timerId } = activeNotifications[index];
  
  // Clear auto-dismiss timer if exists
  if (timerId) {
    clearTimeout(timerId);
  }
  
  // Add fade-out animation
  element.classList.add('fade-out');
  
  // Remove after animation completes
  setTimeout(() => {
    if (element.parentNode) {
      element.parentNode.removeChild(element);
    }
    activeNotifications.splice(index, 1);
  }, ANIMATION_DURATION);
}

/**
 * Dismiss all notifications
 */
export function dismissAllNotifications() {
  [...activeNotifications].forEach(n => dismissNotification(n.id));
}

// Shorthand methods for convenience
export const notify = {
  success: (message, duration) => showNotification('success', message, duration),
  error: (message, duration) => showNotification('error', message, duration),
  info: (message, duration) => showNotification('info', message, duration),
  warning: (message, duration) => showNotification('warning', message, duration)
};