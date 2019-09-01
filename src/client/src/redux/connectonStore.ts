import { Store } from 'redux';

import store from './main';
import { UPDATE_OUTPUT } from './outputStore';

interface ConnectionNotReadyStore {
  status: 'not-ready';
}

interface ConnectionOpenStore {
  status: 'open';
  connection: WebSocket;
  updateInput: (inputHash: string) => void;
  lastError?: string;
}

interface ConnectionClosedStore {
  status: 'closed';
}

export type ConnectionStore = ConnectionNotReadyStore | ConnectionOpenStore | ConnectionClosedStore;

interface ServerUpdateResponse {
  command: 'update';
  output: string; //output hash
  detail: any;
}

export type ServerResponse = ServerUpdateResponse;

export const CONNECTION_OPEN = 'connection-open';
export const CONNECTION_ERROR = 'connection-error';
export const CONNECTION_CLOSE = 'connection-close';

interface OpenConnectionAction {
  type: 'connection-open';
  connection: WebSocket;
  updateInput: (inputHash: string) => void;
}

interface CloseConnectionAction {
  type: 'connection-close';
}

interface ConnectionErrorAction {
  type: 'connection-error';
  message: string;
}

export type ConnectionAction = OpenConnectionAction | CloseConnectionAction | ConnectionErrorAction;

const INITIAL_CONNECTION_STORE: ConnectionStore = {
  status: 'not-ready'
};

export const connectionReducer = (
  store: ConnectionStore = INITIAL_CONNECTION_STORE,
  action: ConnectionAction
): ConnectionStore => {
  switch (action.type) {
    case CONNECTION_OPEN:
      return {
        status: 'open',
        connection: action.connection,
        updateInput: action.updateInput
      }
    case CONNECTION_ERROR:
      return Object.assign(store, { lastError: action.message })
    case CONNECTION_CLOSE:
      return { status: 'closed' }
    default:
      return store;
  }
}

type UpdateBindSet = { [inputHash: string]: any }

class PushManager {
  store: Store;
  connection: WebSocket;
  value: { [bind_hash: string]: UpdateBindSet } = {};
  timeout: { [bind_hash: string]: number } = {};


  constructor(store: Store, connection: WebSocket) {
    this.connection = connection;
    this.store = store;
  }

  updateInput(bind_hash: string) {
    const state = this.store.getState();
    if (state.ui.state != 'success') return

    const inputHashes = state.ui.bind_input;

    if (this.timeout[bind_hash]) {
      window.clearTimeout(this.timeout[bind_hash]);
      delete this.timeout[bind_hash];
    }

    this.timeout[bind_hash] = window.setTimeout(() => {

      const nextUpdateValue: UpdateBindSet = {}

      inputHashes.forEach((inputHash: string) => {
        nextUpdateValue[inputHash] = state.inputs[inputHash];
      });

      const updateRequest = {
        command: 'update',
        bind_set: bind_hash,
        input: nextUpdateValue
      }

      this.connection.send(JSON.stringify(updateRequest));
    }, 1000);
  }
}

export const setupWebSocketConnection = () => {
  const host = location.origin.replace(/^http/, 'ws');

  const connection = new WebSocket(`${host}/MATT-io`);

  const pushManager = new PushManager(store, connection);

  connection.onopen = (event) => {
    store.dispatch({
      type: CONNECTION_OPEN,
      updateInput: pushManager.updateInput,
      connection
    });
  }

  connection.onerror = (event) => {
    store.dispatch({
      type: CONNECTION_ERROR,
      message: 'error!'
    })
  }

  connection.onclose = (event) => {
    store.dispatch({
      type: CONNECTION_CLOSE
    })
  }

  connection.onmessage = (event) => {
    let response;

    try {
      response = JSON.parse(JSON.parse(event.data)) as ServerResponse;
    } catch (e) {
      store.dispatch({
        type: CONNECTION_ERROR,
        message: e.message
      });

      return false
    }

    switch (response.command) {
      case "update":
        store.dispatch({
          type: UPDATE_OUTPUT,
          output: response.output,
          value: response.detail
        });
        
        break;
      default:
        return false;
    }
  }
}