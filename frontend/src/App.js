import React from 'react';
import './App.css';

function App() {
  return (
    <div className="App">
      <div className="container">
        <div className="video-container">
          <iframe
            width="560"
            height="315"
            src="https://www.youtube.com/embed/dQw4w9WgXcQ?autoplay=1&mute=0"
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
