using System;
using System.Collections.Generic;
using UnityEngine;

namespace DustRTS.Core
{
    /// <summary>
    /// Simple service locator for decoupled access to core systems.
    /// Register services on initialization, retrieve them anywhere.
    /// </summary>
    public static class ServiceLocator
    {
        private static readonly Dictionary<Type, object> services = new();
        private static bool isQuitting;

        public static void Register<T>(T service) where T : class
        {
            var type = typeof(T);
            if (services.ContainsKey(type))
            {
                Debug.LogWarning($"[ServiceLocator] Service {type.Name} already registered. Replacing.");
                services[type] = service;
            }
            else
            {
                services.Add(type, service);
            }
        }

        public static void Unregister<T>() where T : class
        {
            var type = typeof(T);
            if (services.ContainsKey(type))
            {
                services.Remove(type);
            }
        }

        public static T Get<T>() where T : class
        {
            if (isQuitting) return null;

            var type = typeof(T);
            if (services.TryGetValue(type, out var service))
            {
                return service as T;
            }

            Debug.LogError($"[ServiceLocator] Service {type.Name} not found. Did you forget to register it?");
            return null;
        }

        public static bool TryGet<T>(out T service) where T : class
        {
            service = null;
            if (isQuitting) return false;

            var type = typeof(T);
            if (services.TryGetValue(type, out var obj))
            {
                service = obj as T;
                return service != null;
            }
            return false;
        }

        public static bool Has<T>() where T : class
        {
            return services.ContainsKey(typeof(T));
        }

        public static void Clear()
        {
            services.Clear();
        }

        [RuntimeInitializeOnLoadMethod(RuntimeInitializeLoadType.SubsystemRegistration)]
        private static void ResetStatics()
        {
            services.Clear();
            isQuitting = false;
        }

        public static void OnApplicationQuitting()
        {
            isQuitting = true;
        }
    }
}
