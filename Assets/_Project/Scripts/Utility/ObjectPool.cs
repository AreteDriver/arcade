using System;
using System.Collections.Generic;
using UnityEngine;

namespace DustRTS.Utility
{
    /// <summary>
    /// Generic object pool for reusing GameObjects.
    /// Use for projectiles, effects, and other frequently spawned objects.
    /// </summary>
    public class ObjectPool : MonoBehaviour
    {
        public static ObjectPool Instance { get; private set; }

        [SerializeField] private int defaultPoolSize = 20;
        [SerializeField] private Transform poolParent;

        private Dictionary<GameObject, Pool> pools = new();

        private void Awake()
        {
            if (Instance != null && Instance != this)
            {
                Destroy(gameObject);
                return;
            }
            Instance = this;

            if (poolParent == null)
            {
                var go = new GameObject("PooledObjects");
                go.transform.SetParent(transform);
                poolParent = go.transform;
            }
        }

        public void Prewarm(GameObject prefab, int count)
        {
            var pool = GetOrCreatePool(prefab);
            for (int i = 0; i < count; i++)
            {
                var obj = CreateInstance(prefab, pool);
                obj.SetActive(false);
                pool.Available.Push(obj);
            }
        }

        public GameObject Get(GameObject prefab)
        {
            var pool = GetOrCreatePool(prefab);
            GameObject obj;

            if (pool.Available.Count > 0)
            {
                obj = pool.Available.Pop();
            }
            else
            {
                obj = CreateInstance(prefab, pool);
            }

            obj.SetActive(true);
            pool.Active.Add(obj);
            return obj;
        }

        public T Get<T>(GameObject prefab) where T : Component
        {
            var obj = Get(prefab);
            return obj.GetComponent<T>();
        }

        public void Return(GameObject obj)
        {
            if (obj == null) return;

            foreach (var pool in pools.Values)
            {
                if (pool.Active.Contains(obj))
                {
                    pool.Active.Remove(obj);
                    obj.SetActive(false);
                    obj.transform.SetParent(poolParent);
                    pool.Available.Push(obj);
                    return;
                }
            }

            // Not from pool, just destroy
            Destroy(obj);
        }

        public void ReturnDelayed(GameObject obj, float delay)
        {
            StartCoroutine(ReturnAfterDelay(obj, delay));
        }

        private System.Collections.IEnumerator ReturnAfterDelay(GameObject obj, float delay)
        {
            yield return new WaitForSeconds(delay);
            Return(obj);
        }

        private Pool GetOrCreatePool(GameObject prefab)
        {
            if (!pools.TryGetValue(prefab, out var pool))
            {
                pool = new Pool
                {
                    Prefab = prefab,
                    Available = new Stack<GameObject>(defaultPoolSize),
                    Active = new HashSet<GameObject>()
                };
                pools[prefab] = pool;
            }
            return pool;
        }

        private GameObject CreateInstance(GameObject prefab, Pool pool)
        {
            var obj = Instantiate(prefab, poolParent);
            obj.name = $"{prefab.name} (Pooled)";

            // Add return-to-pool component if using auto-return
            var poolable = obj.GetComponent<IPoolable>();
            if (poolable != null)
            {
                poolable.OnSpawned();
            }

            return obj;
        }

        public void ClearPool(GameObject prefab)
        {
            if (pools.TryGetValue(prefab, out var pool))
            {
                foreach (var obj in pool.Available)
                {
                    if (obj != null) Destroy(obj);
                }
                foreach (var obj in pool.Active)
                {
                    if (obj != null) Destroy(obj);
                }
                pools.Remove(prefab);
            }
        }

        public void ClearAllPools()
        {
            foreach (var kvp in pools)
            {
                foreach (var obj in kvp.Value.Available)
                {
                    if (obj != null) Destroy(obj);
                }
                foreach (var obj in kvp.Value.Active)
                {
                    if (obj != null) Destroy(obj);
                }
            }
            pools.Clear();
        }

        private class Pool
        {
            public GameObject Prefab;
            public Stack<GameObject> Available;
            public HashSet<GameObject> Active;
        }
    }

    public interface IPoolable
    {
        void OnSpawned();
        void OnDespawned();
    }
}
