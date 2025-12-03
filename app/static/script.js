document.addEventListener("DOMContentLoaded", () => {
    const msg = document.querySelector(".message");
    if (msg && msg.textContent.trim() !== "") {
        msg.style.opacity = "0";
        setTimeout(() => {
            msg.style.opacity = "1";
            msg.style.transition = "0.5s";
        }, 100);
    }
});
