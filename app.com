<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=yes">
    <title>MoviePulse | Stream</title>
    
    <!-- Firebase SDK (config hardcoded in script) -->
    <script src="https://www.gstatic.com/firebasejs/9.6.1/firebase-app-compat.js"></script>
    <script src="https://www.gstatic.com/firebasejs/9.6.1/firebase-database-compat.js"></script>

    <style>
        * {
            box-sizing: border-box;
        }
        :root {
            --bg-black: #0f0f0f;
            --card-bg: #1a1a1a;
            --accent-red: #1a1;
            --text-white: #ffffff;
            --text-gray: #aaaaaa;
            --input-bg: #121212;
        }
        body.light-mode {
            --bg-black: #ffffff;
            --card-bg: #f0f0f0;
            --text-white: #000000;
            --text-gray: #555555;
            --input-bg: #e0e0e0;
        }
        body {
            background-color: var(--bg-black);
            color: var(--text-white);
            font-family: 'Roboto', system-ui, -apple-system, sans-serif;
            margin: 0;
            padding-bottom: 80px;
            transition: background 0.3s, color 0.3s;
        }
        /* Header & Search */
        .app-header {
            padding: 12px 16px;
            display: flex;
            align-items: center;
            gap: 12px;
            background-color: var(--bg-black);
            position: sticky;
            top: 0;
            z-index: 100;
            backdrop-filter: blur(8px);
        }
        .search-container {
            flex: 1;
            display: flex;
            align-items: center;
            background: #222;
            border-radius: 30px;
            padding: 8px 16px;
            border: 2px solid #1a1;
            transition: 1.2s;
        }
        .search-container:focus-within {
            border-color: var(--accent-red);
            box-shadow: 0 0 0 2px rgba(255,0,0,0.2);
        }
        #movie-search {
            background: transparent;
            border: none;
            color: var(--text-white);
            outline: none;
            width: 100%;
            font-size: 1rem;
        }
        .search-icon {
            margin-right: 8px;
            color: var(--text-gray);
        }
        .clear-search {
            cursor: pointer;
            margin-left: auto;
            padding: 0 8px;
            color: var(--text-gray);
            font-size: 1.1rem;
            display: none;
            transition: color 0.2s;
        }
        .clear-search:hover {
            color: var(--accent-red);
        }
        .upload-btn {
            background: var(--accent-red);
            border: none;
            padding: 8px 16px;
            border-radius: 40px;
            font-weight: bold;
            color: white;
            cursor: pointer;
            display: flex;
            align-items: center;
            gap: 6px;
            transition: 0.2s;
        }
        .upload-btn:active { transform: scale(0.96); }
        /* Refresh button */
        .refresh-btn {
            background: #272727;
            border: none;
            padding: 8px 16px;
            border-radius: 40px;
            color: white;
            font-weight: bold;
            cursor: pointer;
            display: flex;
            align-items: center;
            gap: 6px;
        }
        /* Sub navigation */
        .sub-nav {
            display: flex;
            gap: 12px;
            padding: 8px 16px;
            overflow-x: auto;
            scrollbar-width: thin;
        }
        .sub-nav span {
            background: #272727;
            padding: 6px 16px;
            border-radius: 30px;
            font-size: 0.9rem;
            white-space: nowrap;
            cursor: pointer;
            transition: 0.2s;
        }
        .sub-nav span.active {
            background: white;
            color: black;
        }
        body.light-mode .sub-nav span { background: #ddd; color: black; }
        body.light-mode .sub-nav span.active { background: black; color: white; }

        /* ========== FEATURED CAROUSEL (pasta) ========== */
        .carousel-container {
            position: relative;
            width: 100%;
            margin-bottom: 24px;
            overflow: hidden;
            border-radius: 0 0 10px 20px;
        }
        .carousel-slide {
            display: none;
            position: relative;
            width: 100%;
            aspect-ratio: 16 / 9;
            background-size: cover;
            background-position: center;
            cursor: pointer;
        }
        .carousel-slide.active {
            display: block;
            animation: fade 0.5s;
        }
        @keyframes fade {
            from { opacity: 0.4; }
            to { opacity: 1; }
        }
        .carousel-caption {
            position: absolute;
            bottom: 0;
            left: 0;
            right: 0;
            background: linear-gradient(0deg, rgba(0,0,0,0.9) 0%, transparent 100%);
            padding: 30px 20px 20px;
        }
        .carousel-title {
            font-size: 1.8rem;
            font-weight: bold;
            margin-bottom: 6px;
        }
        .carousel-meta {
            font-size: 0.85rem;
            color: #ddd;
        }
        .carousel-badge {
            background: var(--accent-red);
            display: inline-block;
            padding: 4px 12px;
            border-radius: 20px;
            font-size: 0.7rem;
            margin-top: 8px;
        }
        .carousel-dots {
            position: absolute;
            bottom: 12px;
            right: 16px;
            display: flex;
            gap: 8px;
            z-index: 5;
        }
        .dot {
            width: 8px;
            height: 8px;
            background: rgba(255,255,255,0.5);
            border-radius: 80%;
            cursor: pointer;
        }
        .dot.active {
            background: white;
            width: 30px;
            border-radius: 30px;
        }

        /* ========== AD BANNER SECTION (NEW) ========== */
        .ad-banner {
            text-align: center;
            margin: 16px 0;
            min-height: 90px;
            background: rgba(0,0,0,0.1);
            border-radius: 12px;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 0.8rem;
            color: var(--text-gray);
        }
        /* This is where you can place your ad code (AdMob banner, custom HTML, etc.) */

        /* Movie sections */
        .section-container {
            padding: 0 16px;
            margin-bottom: 32px;
        }
        .section-title {
            font-size: 1.2rem;
            font-weight: bold;
            margin-bottom: 12px;
            display: flex;
            align-items: center;
            gap: 8px;
        }
        .horizontal-scroll {
            display: flex;
            gap: 14px;
            overflow-x: auto;
            scrollbar-width: thin;
            padding-bottom: 8px;
        }
        .movie-card {
            min-width: 400px;
            width: 100px;
            flex-shrink: 0;
            cursor: pointer;
            transition: transform 0.2s;
            border-radius: 16px;
            overflow: hidden;
            background: var(--card-bg);
        }
        .movie-card:hover {
            transform: translateY(-4px);
        }
        .card-image {
            width: 100%;
            aspect-ratio: 16 / 9;
            background-size: cover;
            background-position: center;
            position: relative;
        }
        .duration-badge {
            position: absolute;
            bottom: 8px;
            right: 8px;
            background: rgba(0,0,0,0.8);
            padding: 3px 6px;
            border-radius: 5px;
            font-size: 0.7rem;
            font-family: monospace;
        }
        .movie-info {
            padding: 12px;
            display: flex;
            gap: 12px;
        }
        .channel-icon {
            width: 36px;
            height: 36px;
            background: var(--accent-red);
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            font-weight: bold;
            flex-shrink: 0;
        }
        .text-content {
            flex: 1;
        }
        .movie-title {
            font-size: 0.9rem;
            font-weight: 600;
            display: -webkit-box;
            -webkit-line-clamp: 2;
            -webkit-box-orient: vertical;
            overflow: hidden;
        }
        .channel-name {
            font-size: 0.75rem;
            color: var(--text-gray);
            margin: 4px 0;
        }
        .movie-stats {
            font-size: 0.7rem;
            color: var(--text-gray);
            display: flex;
            gap: 8px;
            flex-wrap: wrap;
        }

        /* Player */
        #player-wrapper {
            display: none;
            width: 100%;
            aspect-ratio: 16/9;
            background: black;
            position: sticky;
            top: 0;
            z-index: 200;
        }
        #player-wrapper.visible { display: block; }
        iframe { width: 100%; height: 110%; border: none; }

        /* Settings & others same as before */
        .page { display: none; padding: 30px; }
        .page.active { display: block; }
        .settings-menu {
            background: var(--card-bg);
            border-radius: 10px;
            overflow: hidden;
        }
        .settings-item {
            display: flex;
            justify-content: space-between;
            align-items: center;
            padding: 6px 40px;
            border-bottom: 1px solid rgba(222,222,222,0.1);
            cursor: pointer;
        }
        .settings-left { display: flex; gap: 15px; align-items: center; }
        .toggle-switch {
            width: 48px;
            height: 26px;
            background: #444;
            border-radius: 30px;
            position: relative;
            transition: 0.2s;
        }
        .toggle-switch.active { background: var(--accent-red); }
        .toggle-switch::after {
            content: '';
            width: 22px;
            height: 22px;
            background: white;
            border-radius: 50%;
            position: absolute;
            top: 2px;
            left: 3px;
            transition: 0.2s;
        }
        .toggle-switch.active::after { transform: translateX(22px); }
        .social-grid {
            display: grid;
            grid-template-columns: repeat(2,1fr);
            gap: 10px;
            padding: 0 20px;
            margin-bottom: 20px;
        }
        .social-item {
            background: rgba(255,255,255,0.05);
            padding: 12px;
            border-radius: 14px;
            display: flex;
            align-items: center;
            gap: 12px;
            cursor: pointer;
        }
        /* Modal Upload */
        .modal {
            display: none;
            position: fixed;
            top:0; left:0; width:100%; height:100%;
            background: rgba(0,0,0,0.95);
            z-index: 10000;
            align-items: center;
            justify-content: center;
        }
        .modal.active { display: flex; }
        .modal-content {
            background: var(--card-bg);
            width: 90%;
            max-width: 500px;
            border-radius: 28px;
            padding: 24px;
        }
        .form-group { margin-bottom: 16px; }
        .form-group label { display: block; margin-bottom: 6px; font-weight: 500; }
        .form-group input, .form-group textarea {
            width: 100%;
            padding: 12px;
            border-radius: 14px;
            border: 1px solid #333;
            background: var(--input-bg);
            color: white;
        }
        .preview-img {
            width: 100%;
            border-radius: 16px;
            margin-top: 8px;
            display: none;
        }
        .submit-btn {
            background: var(--accent-red);
            width: 100%;
            padding: 14px;
            border: none;
            border-radius: 40px;
            color: white;
            font-weight: bold;
            font-size: 1rem;
            cursor: pointer;
        }
        .nav-bar {
            position: fixed;
            bottom: 0;
            width: 100%;
            background: var(--bg-black);
            display: flex;
            justify-content: space-around;
            padding: 8px 0;
            border-top: 1px solid #222;
            z-index: 1000;
        }
        .nav-link {
            color: var(--text-white);
            font-size: 1.4rem;
            text-align: center;
            cursor: pointer;
        }
        .nav-link span { display: block; font-size: 0.6rem; }
        .nav-link.active { color: var(--accent-red); }
    </style>
</head>
<body>

<header class="app-header">
    <div class="search-container">
        <span class="search-icon">🔍</span>
        <input type="text" id="movie-search" placeholder="Search movies, channels...">
        <span class="clear-search" id="clearSearchBtn">✕</span>
    </div>
    <button class="refresh-btn" id="refreshBtn">⟳</button>
    <button class="upload-btn" onclick="openUploadModal()">➕ Upload</button>
</header>

<div class="sub-nav" id="app-sub-nav">
    <span class="active" onclick="changeCategory(event, 'all')">All</span>
    <span onclick="changeCategory(event, 'trending')">Trending</span>
    <span onclick="changeCategory(event, 'movie')">Movie Pluse</span>
    <span onclick="changeCategory(event, 'tv')">TV Series</span>
</div>

<div id="player-wrapper"><iframe id="iframe-player"></iframe></div>

<div id="home-page" class="page active">
    <!-- Featured Carousel (Pasta) -->
    <div id="carousel" class="carousel-container"></div>

    <!-- AD BANNER SECTION - You can place any ad network code here -->
    <div id="adBanner" class="ad-banner">
        <!-- Example: Place your AdMob banner code here -->
        <script type="text/javascript">
            // This is a placeholder for your ad code.
            // You can insert Google AdSense, AdMob, or any custom banner.
            // For Capacitor app, you can use cordova-plugin-admob.
            // Example: document.write('<div style="background:#2c2c2c; padding:5px;">Your Banner Ad</div>');
        </script>
        <div style="padding: 10px;">📢 Ad Space (replace with your ad code)</div>
    </div>

    <div id="genre-sections"></div>
</div>

<div id="settings-page" class="page">
    <div class="settings-menu">
        <div class="settings-item" onclick="alert('Account')"><div class="settings-left">👤 Account</div><span>›</span></div>
        <div class="settings-item" onclick="shareApp()"><div class="settings-left">↪️ Share App</div><span>›</span></div>
        <div class="settings-item" onclick="alert('Privacy')"><div class="settings-left">🔒 Privacy</div><span>›</span></div>
        <div class="settings-item" onclick="alert('Contact')"><div class="settings-left">📧 Contact</div><span>›</span></div>
        <div class="settings-item"><div class="settings-left">🔔 Notifications</div><div class="toggle-switch" id="notifications-toggle" onclick="toggleNotifications(event)"></div></div>
        <div class="settings-item"><div class="settings-left">🌙 Dark Mode</div><div class="toggle-switch active" id="darkmode-toggle" onclick="toggleDarkMode(event)"></div></div>
        <!-- AD CONTROL TOGGLE (New but doesn't alter existing design) -->
        <div class="settings-item"><div class="settings-left">📢 Show Ads</div><div class="toggle-switch active" id="adsToggle" onclick="toggleAds(event)"></div></div>
        <div style="margin:20px 20px 10px">⚡ Connect</div>
        <div class="social-grid">
            <div class="social-item" onclick="openSocial('https://facebook.com')"><span>📘</span> Facebook</div>
            <div class="social-item" onclick="openSocial('https://instagram.com')"><span>📷</span> Instagram</div>
            <div class="social-item" onclick="openSocial('https://twitter.com')"><span>🐦</span> Twitter</div>
            <div class="social-item" onclick="openSocial('https://youtube.com')"><span>📺</span> YouTube</div>
        </div>
        <div class="settings-item" onclick="logout()"><div class="settings-left">🚪 Logout</div><span>›</span></div>
        <div class="settings-item danger-item" onclick="deleteAccount()"><div class="settings-left">⚠️ Delete Account</div><span>›</span></div>
    </div>
</div>

<div id="uploadModal" class="modal">
    <div class="modal-content">
        <div class="modal-header" style="display:flex; justify-content:space-between; margin-bottom:16px;">
            <h3>📽️ Upload Movie</h3>
            <button  class="close-modal" onclick="closeUploadModal()" style="background:none; border:none; color:white; font-size:24px;"<span>⬅️</span>➡️</button>
        </div>
        <form id="uploadForm">
            <div class="form-group"><label>Enter Movie/Webseries Link *</label><input type="url" id="movieLink" placeholder="https://exampel.com/movie-link or YouTubeURL" required></div>
            <div class="form-group"><label>Enter Movie//Any Webseries Title *</label><input type="text" id="movieTitle" placeholder="Movie title" required></div>
            <div class="form-group"><label>Type</label><div class="radio-group" style="display:flex; gap:16px;"><label><input type="radio" name="type" value="Movie" checked> Movie</label><label><input type="radio" name="type" value="Series"> Series</label></div></div>
            <div class="form-group"><label>Custom Poster URL (optional)</label><input type="url" id="customPoster" placeholder="https://image.tmdb.org/..."></div>
            <img id="previewThumb" class="preview-img" alt="Preview">
            <button type="submit" class="submit-btn">✅ Upload</button>
        </form>
    </div>
</div>

<nav class="nav-bar">
    <div class="nav-link active" onclick="tab(event, 'home-page')">🏠<span>Home</span></div>
    <div class="nav-link" onclick="alert('Shorts')">©<span>Shorts</span></div>
    <div class="nav-link" onclick="alert('Create')">+</div>
    <div class="nav-link" onclick="alert('Alerts')" alert">🧑‍🔧<span>Alerts</span></div>
    <div class="nav-link" onclick="tab(event, 'settings-page') ">🌏<span>You</span></div>
</nav>

<script>
    // ==================== HARDCODED API KEYS (Edit here) ====================
    const TMDB_KEY = "35ecfedd6b9347fe512bd52ecb3fd1cd";   // TMDB API key
    const YOUTUBE_API_KEY = "";  // PUT YOUR YOUTUBE API KEY HERE (for Hausa sections)
    // Firebase config (hardcoded - replace with your own if needed)
    const firebaseConfig = {
        apiKey: "AIzaSyCb_ICD70DfGMquoGOIHYU7X9ZF77n641I",
        authDomain: "moviepluse-28c9f.firebaseapp.com",
        projectId: "moviepluse-28c9f",
        storageBucket: "moviepluse-28c9f.firebasestorage.app",
        messagingSenderId: "SENDER_ID",
        appId: "1:974462428409:web:1687f998f9ac6321e32e28",
        databaseURL: "https://moviepluse-28c9f-default-rtdb.firebaseio.com/"
    };
    let database = null;
    try {
        firebase.initializeApp(firebaseConfig);
        database = firebase.database();
        console.log("Firebase ready");
    } catch(e) { console.warn("Firebase not configured", e); }
    // =======================================================================

    // Helper functions
    function formatViews(v) { return v>=1e6 ? (v/1e6).toFixed(1)+'M' : v>=1e3 ? (v/1e3).toFixed(1)+'K' : v; }
    function timeAgo(days) { if(days<7) return days+' days ago'; if(days<30) return Math.floor(days/7)+' weeks ago'; if(days<365) return Math.floor(days/30)+' months ago'; return Math.floor(days/365)+' years ago'; }
    function randomStats() {
        return { views: formatViews(Math.floor(Math.random()*5e6)+1e5
