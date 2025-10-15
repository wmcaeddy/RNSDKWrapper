/**
 * Acuant SDK Example App
 *
 * Simple single-screen test app for the Acuant SDK wrapper.
 * Linear workflow: Initialize → Capture Face → Process Liveness → Face Match
 *
 * Design: Keep it simple. No navigation, no fancy state management.
 * All logic in one file. ~400 lines total.
 */

import React, { useState } from 'react';
import {
  SafeAreaView,
  ScrollView,
  StatusBar,
  StyleSheet,
  Text,
  TextInput,
  TouchableOpacity,
  View,
  Image,
  Alert,
  Modal,
  Clipboard,
} from 'react-native';
import AcuantSdk, {
  AcuantRegion,
  type FaceCaptureResult,
  type PassiveLivenessResult,
  type FaceMatchResult,
} from 'react-native-acuant-sdk';

// ============================================================================
// Types
// ============================================================================

interface Config {
  username: string;
  password: string;
  subscription: string;
  region: AcuantRegion;
}

interface LogEntry {
  timestamp: string;
  message: string;
  type: 'info' | 'success' | 'error';
}

interface AppState {
  config: Config | null;
  initialized: boolean;
  faceImage: FaceCaptureResult | null;
  livenessResult: PassiveLivenessResult | null;
  matchResult: FaceMatchResult | null;
  isLoading: boolean;
  logs: LogEntry[];
  showConfigModal: boolean;
  showLogsExpanded: boolean;
}

// ============================================================================
// Main Component
// ============================================================================

export default function App() {
  const [state, setState] = useState<AppState>({
    config: null,
    initialized: false,
    faceImage: null,
    livenessResult: null,
    matchResult: null,
    isLoading: false,
    logs: [],
    showConfigModal: false,
    showLogsExpanded: false,
  });

  // --------------------------------------------------------------------------
  // Logging
  // --------------------------------------------------------------------------

  const addLog = (message: string, type: 'info' | 'success' | 'error' = 'info') => {
    const timestamp = new Date().toLocaleTimeString();
    setState((prev) => ({
      ...prev,
      logs: [{ timestamp, message, type }, ...prev.logs],
    }));
    console.log(`[${type.toUpperCase()}] ${message}`);
  };

  // --------------------------------------------------------------------------
  // SDK Operations
  // --------------------------------------------------------------------------

  const handleInitialize = async () => {
    if (!state.config) {
      Alert.alert('Configuration Required', 'Please configure credentials first.');
      setState((prev) => ({ ...prev, showConfigModal: true }));
      return;
    }

    setState((prev) => ({ ...prev, isLoading: true }));
    addLog('Initializing Acuant SDK...', 'info');

    try {
      await AcuantSdk.initialize({
        credentials: {
          username: state.config.username,
          password: state.config.password,
          subscription: state.config.subscription,
        },
        region: state.config.region,
      });

      setState((prev) => ({ ...prev, initialized: true, isLoading: false }));
      addLog('SDK initialized successfully', 'success');
    } catch (error: any) {
      setState((prev) => ({ ...prev, isLoading: false }));
      addLog(`Initialization failed: ${error.message || error}`, 'error');
      Alert.alert('Initialization Failed', error.message || String(error));
    }
  };

  const handleCaptureFace = async () => {
    setState((prev) => ({ ...prev, isLoading: true }));
    addLog('Launching face capture UI...', 'info');

    try {
      const result = await AcuantSdk.captureFace({
        totalCaptureTime: 2,
        showOval: true,
      });

      const imageSize = result.jpegData ? (result.jpegData.length * 0.75) / 1024 : 0;
      setState((prev) => ({
        ...prev,
        faceImage: result,
        isLoading: false,
      }));
      addLog(`Face captured successfully (${imageSize.toFixed(2)} KB)`, 'success');
    } catch (error: any) {
      setState((prev) => ({ ...prev, isLoading: false }));
      if (error.message?.includes('cancel')) {
        addLog('Face capture cancelled by user', 'info');
      } else {
        addLog(`Face capture failed: ${error.message || error}`, 'error');
        Alert.alert('Capture Failed', error.message || String(error));
      }
    }
  };

  const handleProcessLiveness = async () => {
    if (!state.faceImage) {
      Alert.alert('No Face Image', 'Please capture a face first.');
      return;
    }

    setState((prev) => ({ ...prev, isLoading: true }));
    addLog('Processing passive liveness...', 'info');

    try {
      const result = await AcuantSdk.processPassiveLiveness({
        jpegData: state.faceImage.jpegData,
      });

      setState((prev) => ({
        ...prev,
        livenessResult: result,
        isLoading: false,
      }));
      addLog(
        `Liveness processed: ${result.assessment} (score: ${result.score})`,
        result.assessment === 'Live' ? 'success' : 'error'
      );
    } catch (error: any) {
      setState((prev) => ({ ...prev, isLoading: false }));
      addLog(`Liveness processing failed: ${error.message || error}`, 'error');
      Alert.alert('Liveness Failed', error.message || String(error));
    }
  };

  const handleFaceMatch = async () => {
    if (!state.faceImage) {
      Alert.alert('No Face Image', 'Please capture a face first.');
      return;
    }

    // For demo purposes, we'll match the face against itself
    // In real usage, you'd compare ID photo vs selfie
    setState((prev) => ({ ...prev, isLoading: true }));
    addLog('Processing face match (comparing with itself for demo)...', 'info');

    try {
      const result = await AcuantSdk.processFaceMatch({
        faceOneData: state.faceImage.jpegData,
        faceTwoData: state.faceImage.jpegData,
      });

      setState((prev) => ({
        ...prev,
        matchResult: result,
        isLoading: false,
      }));
      addLog(
        `Face match completed: ${result.isMatch ? 'MATCH' : 'NO MATCH'} (score: ${result.score})`,
        result.isMatch ? 'success' : 'error'
      );
    } catch (error: any) {
      setState((prev) => ({ ...prev, isLoading: false }));
      addLog(`Face match failed: ${error.message || error}`, 'error');
      Alert.alert('Face Match Failed', error.message || String(error));
    }
  };

  const handleRunFullWorkflow = async () => {
    addLog('=== Starting Full Workflow ===', 'info');

    // Initialize
    if (!state.initialized) {
      await handleInitialize();
      if (!state.initialized) return; // Failed
    }

    // Capture
    await handleCaptureFace();
    if (!state.faceImage) return; // Failed or cancelled

    // Liveness
    await handleProcessLiveness();

    // Match
    await handleFaceMatch();

    addLog('=== Workflow Complete ===', 'success');
  };

  const handleReset = () => {
    setState((prev) => ({
      ...prev,
      initialized: false,
      faceImage: null,
      livenessResult: null,
      matchResult: null,
      logs: [],
    }));
    addLog('State reset', 'info');
  };

  // --------------------------------------------------------------------------
  // Configuration Modal
  // --------------------------------------------------------------------------

  const ConfigModal = () => {
    const [tempConfig, setTempConfig] = useState<Config>(
      state.config || {
        username: '',
        password: '',
        subscription: '',
        region: AcuantRegion.USA,
      }
    );

    return (
      <Modal
        visible={state.showConfigModal}
        animationType="slide"
        presentationStyle="pageSheet"
      >
        <SafeAreaView style={styles.modalContainer}>
          <View style={styles.modalHeader}>
            <Text style={styles.modalTitle}>SDK Configuration</Text>
          </View>

          <ScrollView style={styles.modalContent}>
            <Text style={styles.label}>Username</Text>
            <TextInput
              style={styles.input}
              value={tempConfig.username}
              onChangeText={(text) => setTempConfig({ ...tempConfig, username: text })}
              placeholder="Enter username"
              autoCapitalize="none"
              autoCorrect={false}
            />

            <Text style={styles.label}>Password</Text>
            <TextInput
              style={styles.input}
              value={tempConfig.password}
              onChangeText={(text) => setTempConfig({ ...tempConfig, password: text })}
              placeholder="Enter password"
              secureTextEntry
              autoCapitalize="none"
              autoCorrect={false}
            />

            <Text style={styles.label}>Subscription ID</Text>
            <TextInput
              style={styles.input}
              value={tempConfig.subscription}
              onChangeText={(text) => setTempConfig({ ...tempConfig, subscription: text })}
              placeholder="Enter subscription ID"
              autoCapitalize="none"
              autoCorrect={false}
            />

            <Text style={styles.label}>Region</Text>
            <View style={styles.regionButtons}>
              {Object.values(AcuantRegion).map((region) => (
                <TouchableOpacity
                  key={region}
                  style={[
                    styles.regionButton,
                    tempConfig.region === region && styles.regionButtonActive,
                  ]}
                  onPress={() => setTempConfig({ ...tempConfig, region })}
                >
                  <Text
                    style={[
                      styles.regionButtonText,
                      tempConfig.region === region && styles.regionButtonTextActive,
                    ]}
                  >
                    {region}
                  </Text>
                </TouchableOpacity>
              ))}
            </View>
          </ScrollView>

          <View style={styles.modalFooter}>
            <TouchableOpacity
              style={[styles.button, styles.buttonSecondary]}
              onPress={() => setState((prev) => ({ ...prev, showConfigModal: false }))}
            >
              <Text style={styles.buttonSecondaryText}>Cancel</Text>
            </TouchableOpacity>
            <TouchableOpacity
              style={[styles.button, styles.buttonPrimary]}
              onPress={() => {
                setState((prev) => ({
                  ...prev,
                  config: tempConfig,
                  showConfigModal: false,
                }));
                addLog('Configuration saved', 'info');
              }}
            >
              <Text style={styles.buttonText}>Save</Text>
            </TouchableOpacity>
          </View>
        </SafeAreaView>
      </Modal>
    );
  };

  // --------------------------------------------------------------------------
  // Render
  // --------------------------------------------------------------------------

  return (
    <SafeAreaView style={styles.container}>
      <StatusBar barStyle="dark-content" />
      <ConfigModal />

      <ScrollView style={styles.content}>
        {/* Header */}
        <View style={styles.header}>
          <Text style={styles.title}>Acuant SDK Test</Text>
          <TouchableOpacity
            style={styles.configButton}
            onPress={() => setState((prev) => ({ ...prev, showConfigModal: true }))}
          >
            <Text style={styles.configButtonText}>⚙️ Config</Text>
          </TouchableOpacity>
        </View>

        {/* Status Indicators */}
        <View style={styles.section}>
          <View style={styles.statusRow}>
            <StatusIndicator label="Initialized" active={state.initialized} />
            <StatusIndicator label="Face Captured" active={!!state.faceImage} />
            <StatusIndicator
              label="Liveness"
              active={state.livenessResult?.assessment === 'Live'}
            />
            <StatusIndicator label="Match" active={state.matchResult?.isMatch} />
          </View>
        </View>

        {/* Face Image Preview */}
        {state.faceImage && (
          <View style={styles.section}>
            <Text style={styles.sectionTitle}>Captured Face</Text>
            <Image
              source={{ uri: `data:image/jpeg;base64,${state.faceImage.jpegData}` }}
              style={styles.faceImage}
              resizeMode="contain"
            />
          </View>
        )}

        {/* Results */}
        {state.livenessResult && (
          <View style={styles.section}>
            <Text style={styles.sectionTitle}>Liveness Result</Text>
            <ResultBox
              label="Assessment"
              value={state.livenessResult.assessment}
              isGood={state.livenessResult.assessment === 'Live'}
            />
            <ResultBox label="Score" value={state.livenessResult.score.toFixed(4)} />
          </View>
        )}

        {state.matchResult && (
          <View style={styles.section}>
            <Text style={styles.sectionTitle}>Match Result</Text>
            <ResultBox
              label="Match"
              value={state.matchResult.isMatch ? 'YES' : 'NO'}
              isGood={state.matchResult.isMatch}
            />
            <ResultBox label="Score" value={state.matchResult.score.toFixed(4)} />
          </View>
        )}

        {/* Action Buttons */}
        <View style={styles.section}>
          <ActionButton
            title="Initialize SDK"
            onPress={handleInitialize}
            disabled={state.initialized || state.isLoading || !state.config}
            loading={state.isLoading}
          />
          <ActionButton
            title="Capture Face"
            onPress={handleCaptureFace}
            disabled={!state.initialized || state.isLoading}
            loading={state.isLoading}
          />
          <ActionButton
            title="Process Liveness"
            onPress={handleProcessLiveness}
            disabled={!state.faceImage || state.isLoading}
            loading={state.isLoading}
          />
          <ActionButton
            title="Face Match"
            onPress={handleFaceMatch}
            disabled={!state.faceImage || state.isLoading}
            loading={state.isLoading}
          />

          <View style={styles.divider} />

          <ActionButton
            title="▶️ Run Full Workflow"
            onPress={handleRunFullWorkflow}
            disabled={state.isLoading || !state.config}
            loading={state.isLoading}
            primary
          />

          <ActionButton
            title="🔄 Reset"
            onPress={handleReset}
            disabled={state.isLoading}
          />
        </View>

        {/* Logs */}
        <View style={styles.section}>
          <View style={styles.logsHeader}>
            <Text style={styles.sectionTitle}>Logs ({state.logs.length})</Text>
            <View style={styles.logsButtons}>
              <TouchableOpacity
                onPress={() =>
                  setState((prev) => ({
                    ...prev,
                    showLogsExpanded: !prev.showLogsExpanded,
                  }))
                }
              >
                <Text style={styles.logsButton}>
                  {state.showLogsExpanded ? '▼' : '▶️'}
                </Text>
              </TouchableOpacity>
              <TouchableOpacity onPress={() => Clipboard.setString(
                state.logs.map(l => `[${l.timestamp}] ${l.message}`).join('\n')
              )}>
                <Text style={styles.logsButton}>📋</Text>
              </TouchableOpacity>
              <TouchableOpacity
                onPress={() => setState((prev) => ({ ...prev, logs: [] }))}
              >
                <Text style={styles.logsButton}>🗑️</Text>
              </TouchableOpacity>
            </View>
          </View>

          {state.showLogsExpanded && (
            <View style={styles.logsContainer}>
              {state.logs.length === 0 ? (
                <Text style={styles.logEmpty}>No logs yet</Text>
              ) : (
                state.logs.map((log, index) => (
                  <View key={index} style={styles.logEntry}>
                    <Text style={styles.logTimestamp}>{log.timestamp}</Text>
                    <Text
                      style={[
                        styles.logMessage,
                        log.type === 'error' && styles.logError,
                        log.type === 'success' && styles.logSuccess,
                      ]}
                    >
                      {log.message}
                    </Text>
                  </View>
                ))
              )}
            </View>
          )}
        </View>
      </ScrollView>
    </SafeAreaView>
  );
}

// ============================================================================
// Subcomponents
// ============================================================================

function StatusIndicator({ label, active }: { label: string; active: boolean }) {
  return (
    <View style={styles.statusIndicator}>
      <View style={[styles.statusDot, active && styles.statusDotActive]} />
      <Text style={styles.statusLabel}>{label}</Text>
    </View>
  );
}

function ResultBox({
  label,
  value,
  isGood,
}: {
  label: string;
  value: string | number;
  isGood?: boolean;
}) {
  return (
    <View style={styles.resultBox}>
      <Text style={styles.resultLabel}>{label}</Text>
      <Text
        style={[
          styles.resultValue,
          isGood === true && styles.resultValueGood,
          isGood === false && styles.resultValueBad,
        ]}
      >
        {value}
      </Text>
    </View>
  );
}

function ActionButton({
  title,
  onPress,
  disabled,
  loading,
  primary,
}: {
  title: string;
  onPress: () => void;
  disabled?: boolean;
  loading?: boolean;
  primary?: boolean;
}) {
  return (
    <TouchableOpacity
      style={[
        styles.actionButton,
        primary && styles.actionButtonPrimary,
        disabled && styles.actionButtonDisabled,
      ]}
      onPress={onPress}
      disabled={disabled || loading}
    >
      <Text
        style={[
          styles.actionButtonText,
          primary && styles.actionButtonTextPrimary,
          disabled && styles.actionButtonTextDisabled,
        ]}
      >
        {loading ? '⏳ Loading...' : title}
      </Text>
    </TouchableOpacity>
  );
}

// ============================================================================
// Styles
// ============================================================================

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#f5f5f5',
  },
  content: {
    flex: 1,
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    padding: 20,
    backgroundColor: '#fff',
    borderBottomWidth: 1,
    borderBottomColor: '#e0e0e0',
  },
  title: {
    fontSize: 24,
    fontWeight: 'bold',
    color: '#333',
  },
  configButton: {
    padding: 8,
  },
  configButtonText: {
    fontSize: 16,
  },
  section: {
    backgroundColor: '#fff',
    marginTop: 12,
    padding: 16,
  },
  sectionTitle: {
    fontSize: 18,
    fontWeight: '600',
    color: '#333',
    marginBottom: 12,
  },
  statusRow: {
    flexDirection: 'row',
    justifyContent: 'space-around',
  },
  statusIndicator: {
    alignItems: 'center',
  },
  statusDot: {
    width: 12,
    height: 12,
    borderRadius: 6,
    backgroundColor: '#ccc',
    marginBottom: 4,
  },
  statusDotActive: {
    backgroundColor: '#4caf50',
  },
  statusLabel: {
    fontSize: 12,
    color: '#666',
  },
  faceImage: {
    width: '100%',
    height: 300,
    backgroundColor: '#f0f0f0',
    borderRadius: 8,
  },
  resultBox: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    paddingVertical: 8,
    borderBottomWidth: 1,
    borderBottomColor: '#f0f0f0',
  },
  resultLabel: {
    fontSize: 16,
    color: '#666',
  },
  resultValue: {
    fontSize: 16,
    fontWeight: '600',
    color: '#333',
  },
  resultValueGood: {
    color: '#4caf50',
  },
  resultValueBad: {
    color: '#f44336',
  },
  divider: {
    height: 1,
    backgroundColor: '#e0e0e0',
    marginVertical: 12,
  },
  actionButton: {
    backgroundColor: '#fff',
    padding: 16,
    borderRadius: 8,
    marginBottom: 8,
    borderWidth: 1,
    borderColor: '#2196f3',
  },
  actionButtonPrimary: {
    backgroundColor: '#2196f3',
  },
  actionButtonDisabled: {
    borderColor: '#ccc',
    backgroundColor: '#f5f5f5',
  },
  actionButtonText: {
    textAlign: 'center',
    fontSize: 16,
    fontWeight: '600',
    color: '#2196f3',
  },
  actionButtonTextPrimary: {
    color: '#fff',
  },
  actionButtonTextDisabled: {
    color: '#999',
  },
  logsHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  logsButtons: {
    flexDirection: 'row',
    gap: 12,
  },
  logsButton: {
    fontSize: 16,
    padding: 4,
  },
  logsContainer: {
    marginTop: 8,
    maxHeight: 300,
  },
  logEmpty: {
    color: '#999',
    fontStyle: 'italic',
    textAlign: 'center',
    paddingVertical: 20,
  },
  logEntry: {
    flexDirection: 'row',
    paddingVertical: 4,
    gap: 8,
  },
  logTimestamp: {
    fontSize: 12,
    color: '#999',
    width: 80,
  },
  logMessage: {
    flex: 1,
    fontSize: 12,
    color: '#333',
  },
  logError: {
    color: '#f44336',
  },
  logSuccess: {
    color: '#4caf50',
  },
  modalContainer: {
    flex: 1,
    backgroundColor: '#fff',
  },
  modalHeader: {
    padding: 20,
    borderBottomWidth: 1,
    borderBottomColor: '#e0e0e0',
  },
  modalTitle: {
    fontSize: 24,
    fontWeight: 'bold',
    color: '#333',
  },
  modalContent: {
    flex: 1,
    padding: 20,
  },
  modalFooter: {
    flexDirection: 'row',
    padding: 20,
    gap: 12,
    borderTopWidth: 1,
    borderTopColor: '#e0e0e0',
  },
  label: {
    fontSize: 16,
    fontWeight: '600',
    color: '#333',
    marginTop: 12,
    marginBottom: 8,
  },
  input: {
    borderWidth: 1,
    borderColor: '#ccc',
    borderRadius: 8,
    padding: 12,
    fontSize: 16,
    backgroundColor: '#fff',
  },
  regionButtons: {
    flexDirection: 'row',
    gap: 8,
    flexWrap: 'wrap',
  },
  regionButton: {
    paddingHorizontal: 16,
    paddingVertical: 8,
    borderRadius: 8,
    borderWidth: 1,
    borderColor: '#ccc',
    backgroundColor: '#fff',
  },
  regionButtonActive: {
    backgroundColor: '#2196f3',
    borderColor: '#2196f3',
  },
  regionButtonText: {
    fontSize: 14,
    color: '#666',
  },
  regionButtonTextActive: {
    color: '#fff',
    fontWeight: '600',
  },
  button: {
    flex: 1,
    padding: 16,
    borderRadius: 8,
    alignItems: 'center',
  },
  buttonPrimary: {
    backgroundColor: '#2196f3',
  },
  buttonSecondary: {
    backgroundColor: '#fff',
    borderWidth: 1,
    borderColor: '#ccc',
  },
  buttonText: {
    fontSize: 16,
    fontWeight: '600',
    color: '#fff',
  },
  buttonSecondaryText: {
    fontSize: 16,
    fontWeight: '600',
    color: '#666',
  },
});
