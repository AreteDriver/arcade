using UnityEngine;

namespace DustRTS.Units.Core
{
    /// <summary>
    /// ScriptableObject defining weapon properties.
    /// </summary>
    [CreateAssetMenu(fileName = "Weapon", menuName = "RTS/Weapon Data")]
    public class WeaponData : ScriptableObject
    {
        [Header("Identity")]
        public string weaponName = "Weapon";
        public Sprite icon;

        [Header("Damage")]
        public int damage = 10;
        public DamageType damageType = DamageType.Kinetic;
        public float damageRandomVariance = 0.1f;

        [Header("Range")]
        public float range = 20f;
        public float minRange = 0f;

        [Header("Fire Rate")]
        public float fireRate = 2f; // Shots per second
        public int burstCount = 1;
        public float burstDelay = 0.1f;

        [Header("Accuracy")]
        public float spread = 2f; // Degrees
        public float spreadIncrease = 0.5f; // Per shot while firing
        public float spreadDecay = 5f; // Per second

        [Header("Ammo & Reload")]
        public int magazineSize = 30;
        public float reloadTime = 2f;
        public bool infiniteAmmo = false;

        [Header("Projectile")]
        public bool isHitscan = true;
        public GameObject projectilePrefab;
        public float projectileSpeed = 50f;

        [Header("Suppression")]
        public float suppressionPerHit = 0.05f;
        public float suppressionPerMiss = 0.02f;

        [Header("Effects")]
        public GameObject muzzleFlashPrefab;
        public GameObject impactEffectPrefab;
        public GameObject tracerPrefab;
        public float tracerChance = 0.25f;

        [Header("Audio")]
        public AudioClip fireSound;
        public AudioClip reloadSound;
        public AudioClip impactSound;

        [Header("Special")]
        public bool isAntiVehicle = false;
        public bool isAntiAir = false;
        public float areaOfEffect = 0f;
        public bool canTargetGround = false;

        public float FireInterval => 1f / fireRate;

        public int GetDamage()
        {
            if (damageRandomVariance <= 0f) return damage;
            float variance = Random.Range(-damageRandomVariance, damageRandomVariance);
            return Mathf.RoundToInt(damage * (1f + variance));
        }
    }

    public enum DamageType
    {
        Kinetic,        // Standard bullets
        ArmorPiercing,  // AT weapons, bonus vs armor
        HighExplosive,  // Grenades, bonus vs infantry
        Energy,         // Lasers
        EMP             // Disables electronics, no damage
    }
}
