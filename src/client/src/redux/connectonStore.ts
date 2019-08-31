import store from './main';

interface ConnectionNotReadyStore {
  status: 'not-ready';
}

interface ConnectionOpenStore {
  status: 'open';
  connection: WebSocket;
  lastError?: string;
}

interface ConnectionClosedStore {
  status: 'closed';
}

export type ConnectionStore = ConnectionNotReadyStore | ConnectionOpenStore | ConnectionClosedStore;

export const CONNECTION_OPEN = 'connection-open';
export const CONNECTION_ERROR = 'connection-error';
export const CONNECTION_CLOSE = 'connection-close';

interface OpenConnectionAction {
  type: 'connection-open';
  connection: WebSocket;
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
        connection: action.connection
      }
    case CONNECTION_ERROR:
      return Object.assign(store, { lastError: action.message })
    case CONNECTION_CLOSE:
      return { status: 'closed' }
    default:
      return store;
  }
}

export const setupWebSocketConnection = () => {
  const host = location.origin.replace(/^http/, 'ws');

  const connection = new WebSocket(`${host}/MATT-io`);

  connection.onopen = (event) => {
    store.dispatch({
      type: CONNECTION_OPEN,
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
    console.log(event.data)
  }
}