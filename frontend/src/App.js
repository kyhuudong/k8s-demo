import React from 'react';
import './App.css';

function App() {
  return (
    <div className="App">
      <div className="container">
        <div className="content">
          <h1 className="title">🎉 Thank You for Listening! 🎉</h1>

          <div className="image-container">
            <img
              src="https://raw.githubusercontent.com/kubernetes/kubernetes/master/logo/logo.png"
              alt="Kubernetes Logo"
              className="k8s-logo"
            />
          </div>

          <div className="message">
            <p className="subtitle">Kubernetes Demo - High Availability & Resilience</p>
            <p className="description">
              We demonstrated how Kubernetes maintains 99%+ uptime through:
            </p>
            <ul className="features">
              <li>✓ Self-Healing Pods</li>
              <li>✓ Automatic Load Balancing</li>
              <li>✓ Zero-Downtime Deployments</li>
              <li>✓ Auto-Recovery from Failures</li>
            </ul>
          </div>

          <div className="footer">
            <p>🚀 Built with NestJS, MySQL, and Kubernetes 🚀</p>
          </div>
        </div>
      </div>
    </div>
  );
}

export default App;
