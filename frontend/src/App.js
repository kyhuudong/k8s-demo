import React from 'react';
import './App.css';

function App() {
  // Generate random positions for floating images
  const floatingImages = Array.from({ length: 8 }, (_, i) => ({
    id: i,
    top: Math.random() * 80 + 10, // 10-90% from top
    left: Math.random() * 80 + 10, // 10-90% from left
    delay: Math.random() * 5, // Random animation delay
    duration: 15 + Math.random() * 10, // 15-25s animation
  }));

  return (
    <div className="App">
      {/* Floating images in background */}
      {floatingImages.map((img) => (
        <img
          key={img.id}
          src="/IMG_7630.png"
          alt="Profile"
          className="floating-profile"
          style={{
            top: `${img.top}%`,
            left: `${img.left}%`,
            animationDelay: `${img.delay}s`,
            animationDuration: `${img.duration}s`,
          }}
        />
      ))}

      <div className="container">
        <div className="video-container">
          <iframe
            width="480"
            height="270"
            src="https://www.youtube.com/embed/dQw4w9WgXcQ?autoplay=1&mute=1&loop=1&playlist=dQw4w9WgXcQ"
            title="70s Vibes"
            frameBorder="0"
            allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
            allowFullScreen
            className="retro-video"
          ></iframe>
        </div>

        <h1 className="retro-text">
          <span className="groovy">Thank You</span>
          <span className="peace">for Listening!</span>
        </h1>
      </div>
    </div>
  );
}

export default App;
